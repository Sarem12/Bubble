import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/websocket_client.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../data/repositories/chat_repository_impl.dart';
import 'chat_controller.dart';

class ActiveChatState {
  final List<Message> messages;
  final bool isFriendOnline;
  final bool isFriendTyping;
  final String lastActiveText;
  final bool isConversationDeleted;

  const ActiveChatState({
    this.messages = const [],
    this.isFriendOnline = false,
    this.isFriendTyping = false,
    this.lastActiveText = '',
    this.isConversationDeleted = false,
  });

  ActiveChatState copyWith({
    List<Message>? messages,
    bool? isFriendOnline,
    bool? isFriendTyping,
    String? lastActiveText,
    bool? isConversationDeleted,
  }) {
    return ActiveChatState(
      messages: messages ?? this.messages,
      isFriendOnline: isFriendOnline ?? this.isFriendOnline,
      isFriendTyping: isFriendTyping ?? this.isFriendTyping,
      lastActiveText: lastActiveText ?? this.lastActiveText,
      isConversationDeleted: isConversationDeleted ?? this.isConversationDeleted,
    );
  }
}

final activeChatControllerProvider =
    AsyncNotifierProvider.family<ActiveChatController, ActiveChatState, String>(
  (conversationId) => ActiveChatController(conversationId),
);

class ActiveChatController extends AsyncNotifier<ActiveChatState> {
  final String conversationId;
  ActiveChatController(this.conversationId);

  late ChatRepository _repository;
  late WebSocketClient _wsClient;
  Timer? _typingTimeoutTimer;
  Timer? _presenceTimer;
  ProviderSubscription<AsyncValue<dynamic>>? _liveSub;
  ProviderSubscription<AsyncValue<ConnectionStateStatus>>? _wsStatusSub;

  @override
  FutureOr<ActiveChatState> build() async {
    _repository = ref.read(chatRepositoryProvider);
    _wsClient = ref.read(webSocketClientProvider);

    // Initial message fetch with offline fallback
    List<Message> initialMessages = [];
    try {
      initialMessages = await _repository.getMessages(conversationId);
    } catch (_) {
      // Graceful offline fallback: allows UI to load so messages can be typed/queued while offline
    }

    // Listen to WebSocket stream cleanly in controller lifecycle
    _liveSub?.close();
    _liveSub = ref.listen<AsyncValue<dynamic>>(liveMessageStreamProvider, (prev, next) {
      if (next.hasValue && next.value != null) {
        _handleIncomingSocketPayload(next.value);
      }
    });

    // Listen to WebSocket connection status for clean auto-reconnect sync
    _wsStatusSub?.close();
    _wsStatusSub = ref.listen<AsyncValue<ConnectionStateStatus>>(wsStatusProvider, (prev, next) {
      if (next.hasValue && next.value == ConnectionStateStatus.connected) {
        if (prev?.value != ConnectionStateStatus.connected) {
          refresh();
          // Delayed refresh to catch any messages from flushed offline queue
          Future.delayed(const Duration(milliseconds: 1000), () {
            refresh();
          });
        }
      }
    });

    ref.onDispose(() {
      _typingTimeoutTimer?.cancel();
      _presenceTimer?.cancel();
      _liveSub?.close();
      _wsStatusSub?.close();
    });

    return ActiveChatState(messages: initialMessages);
  }

  Future<void> refresh() async {
    try {
      final serverMessages = await _repository.getMessages(conversationId);
      final current = state.value;
      if (current != null) {
        final serverIds = serverMessages.map((m) => m.id).toSet();
        final serverContents = serverMessages.map((m) => m.content).toSet();
        final pendingOptimistic = current.messages.where((m) =>
          m.isOptimistic &&
          !serverIds.contains(m.id) &&
          !serverContents.contains(m.content)
        ).toList();
        state = AsyncData(current.copyWith(messages: [...pendingOptimistic, ...serverMessages]));
      }
    } catch (_) {}
  }

  void _handleIncomingSocketPayload(dynamic raw) {
    try {
      final Map<String, dynamic> payload = raw is String
          ? jsonDecode(raw)
          : (raw is Map<String, dynamic> ? raw : {});

      final type = payload['type'];

      if (type == 'presence_update') {
        final online = payload['status'] == 'online';
        final updateUserId = (payload['user_id'] ?? '').toString();
        final current = state.value;
        if (current != null) {
          bool isPartner = false;
          if (updateUserId.isNotEmpty) {
            for (final m in current.messages) {
              if (m.senderId == updateUserId || m.recipientId == updateUserId) {
                isPartner = true;
                break;
              }
            }
          }
          if (isPartner || updateUserId.isEmpty) {
            state = AsyncData(current.copyWith(
              isFriendOnline: online,
              lastActiveText: online ? '' : 'Active just now',
              isFriendTyping: online ? current.isFriendTyping : false,
            ));
          }
        }
        return;
      }

      if (type == 'delete_message' && payload['conversation_id'] == conversationId) {
        final deletedId = (payload['message_id'] ?? '').toString();
        final current = state.value;
        if (current != null) {
          final updated = current.messages.where((m) => m.id != deletedId).toList();
          state = AsyncData(current.copyWith(messages: updated));
        }
        return;
      }

      if (type == 'reaction_update' && payload['conversation_id'] == conversationId) {
        final msgId = (payload['message_id'] ?? '').toString();
        final rawReactions = payload['reactions'];
        final List<Reaction> newReactions = [];
        if (rawReactions is List) {
          for (final r in rawReactions) {
            if (r is Map<String, dynamic>) {
              newReactions.add(Reaction.fromJson(r));
            }
          }
        }
        final current = state.value;
        if (current != null) {
          final updated = current.messages.map((m) {
            if (m.id == msgId) {
              return m.copyWith(reactions: newReactions);
            }
            return m;
          }).toList();
          state = AsyncData(current.copyWith(messages: updated));
        }
        return;
      }

      if (type == 'conversation_deleted' && payload['conversation_id'] == conversationId) {
        final current = state.value;
        if (current != null) {
          state = AsyncData(current.copyWith(isConversationDeleted: true));
        }
        return;
      }

      if (type == 'typing' && (payload['conversation_id'] == null || payload['conversation_id'] == conversationId)) {
        final current = state.value;
        if (current != null) {
          state = AsyncData(current.copyWith(isFriendTyping: true));
          _typingTimeoutTimer?.cancel();
          _typingTimeoutTimer = Timer(const Duration(seconds: 4), () {
            final active = state.value;
            if (active != null) {
              state = AsyncData(active.copyWith(isFriendTyping: false));
            }
          });
        }
        return;
      }

      if (type == 'read_receipt' && payload['conversation_id'] == conversationId) {
        final current = state.value;
        if (current != null) {
          final readTime = payload['read_at'] != null
              ? DateTime.tryParse(payload['read_at'].toString())?.toLocal() ?? DateTime.now()
              : DateTime.now();
          final readerId = (payload['reader_id'] ?? '').toString();
          final updated = current.messages.map((m) {
            if (m.readAt == null && (readerId.isEmpty || m.senderId != readerId)) {
              return m.copyWith(readAt: readTime, isOptimistic: false);
            }
            return m;
          }).toList();
          state = AsyncData(current.copyWith(messages: updated));
        }
        return;
      }

      // Normal or new chat message: unwrap message object if nested
      final Map<String, dynamic> messageData = (payload['message'] is Map<String, dynamic>)
          ? payload['message'] as Map<String, dynamic>
          : payload;

      final msgConvId = (messageData['conversation_id'] ?? payload['conversation_id'])?.toString();
      final clientId = (payload['client_id'] ?? messageData['client_id'])?.toString();

      if (msgConvId == conversationId &&
          type != 'typing' &&
          type != 'read_receipt' &&
          type != 'presence_update' &&
          type != 'delete_message' &&
          type != 'reaction_update' &&
          type != 'conversation_deleted') {
        final incoming = Message.fromJson(messageData);
        final current = state.value;
        if (current != null) {
          final matchIndex = current.messages.indexWhere((m) =>
              (clientId != null && clientId.isNotEmpty && m.id == clientId) ||
              (m.id == incoming.id) ||
              (m.isOptimistic && m.senderId == incoming.senderId && m.content == incoming.content));

          final updated = List<Message>.from(current.messages);
          if (matchIndex != -1) {
            updated[matchIndex] = incoming.copyWith(isOptimistic: false);
          } else {
            if (!updated.any((m) => m.id == incoming.id)) {
              updated.insert(0, incoming.copyWith(isOptimistic: false));
            }
          }
          state = AsyncData(current.copyWith(messages: updated, isFriendTyping: false));
        }
      }
    } catch (_) {}
  }

  void startPresenceTracking(String? targetId) {
    if (targetId == null || targetId.isEmpty) return;
    checkPresence(targetId);
    _presenceTimer?.cancel();
    _presenceTimer = Timer.periodic(const Duration(seconds: 5), (_) => checkPresence(targetId));
  }

  void checkPresence(String? targetId) async {
    if (targetId == null || targetId.isEmpty) return;
    final online = await _repository.getPresence(targetId);
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(
        isFriendOnline: online,
        lastActiveText: online ? '' : (current.lastActiveText.isEmpty ? 'Offline' : current.lastActiveText),
      ));
    }
  }

  void sendMessage({
    required String text,
    required String myId,
    required String? targetId,
  }) {
    if (text.trim().isEmpty) return;

    final current = state.value;
    String resolvedTargetId = targetId ?? '';
    if (resolvedTargetId.isEmpty && current != null) {
      for (final m in current.messages) {
        if (m.senderId.isNotEmpty && m.senderId != myId) {
          resolvedTargetId = m.senderId;
          break;
        }
        if (m.recipientId.isNotEmpty && m.recipientId != myId) {
          resolvedTargetId = m.recipientId;
          break;
        }
      }
    }

    final optimisticMsg = Message(
      id: const Uuid().v4(),
      conversationId: conversationId,
      topic: 'general',
      senderId: myId,
      recipientId: resolvedTargetId,
      content: text.trim(),
      createdAt: DateTime.now(),
      isOptimistic: true,
    );

    if (current != null) {
      final updated = [optimisticMsg, ...current.messages];
      state = AsyncData(current.copyWith(messages: updated));
    }

    _wsClient.sendMessage(
      conversationId,
      resolvedTargetId,
      text.trim(),
      clientId: optimisticMsg.id,
    );
  }

  void sendTyping(String targetId) {
    _wsClient.sendTyping(conversationId, targetId);
  }

  void markAsRead(String targetId) {
    _wsClient.markAsRead(conversationId, targetId);
  }

  void toggleReaction(Message msg, String emoji, String targetId, [String? myId]) {
    final current = state.value;
    if (current != null && myId != null && myId.isNotEmpty) {
      final existingIndex = msg.reactions.indexWhere((r) => r.emoji == emoji && r.userId == myId);
      final updatedReactions = List<Reaction>.from(msg.reactions);
      if (existingIndex != -1) {
        updatedReactions.removeAt(existingIndex);
      } else {
        updatedReactions.add(Reaction(userId: myId, emoji: emoji));
      }
      final updated = current.messages.map((m) {
        if (m.id == msg.id) {
          return m.copyWith(reactions: updatedReactions);
        }
        return m;
      }).toList();
      state = AsyncData(current.copyWith(messages: updated));
    }

    _wsClient.reactMessage(conversationId, targetId, msg.id, emoji);
    _repository.toggleReaction(msg.id, emoji);
  }

  void deleteMessage(Message msg, String targetId) {
    final current = state.value;
    if (current != null) {
      final updated = current.messages.where((m) => m.id != msg.id).toList();
      state = AsyncData(current.copyWith(messages: updated));
    }

    _wsClient.deleteMessage(conversationId, targetId, msg.id);
    _repository.deleteMessage(msg.id, conversationId);
  }

  Future<void> deleteConversation(String targetId) async {
    _wsClient.deleteConversation(conversationId, targetId);
    await _repository.deleteConversation(conversationId);
  }
}
