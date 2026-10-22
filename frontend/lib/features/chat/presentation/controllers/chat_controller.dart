import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/websocket_client.dart';
import '../../data/datasources/chat_remote_datasource.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';

final webSocketClientProvider = Provider((ref) => WebSocketClient());
final chatDataSourceProvider = Provider((ref) => ChatRemoteDataSource());

// Connection status provider
final wsStatusProvider = StreamProvider<ConnectionStateStatus>((ref) async* {
  final wsClient = ref.watch(webSocketClientProvider);
  yield wsClient.status;
  yield* wsClient.statusStream;
});

// 1. Provider to load active conversations (Inbox)
final conversationsProvider = FutureProvider<List<EnrichedConversation>>((ref) async {
  final dataSource = ref.read(chatDataSourceProvider);
  return await dataSource.getConversations();
});

// 2. Provider to load historical messages for a specific chat
final chatHistoryProvider = FutureProvider.family.autoDispose<List<Message>, String>((ref, conversationId) async {
  final dataSource = ref.read(chatDataSourceProvider);
  return await dataSource.getMessages(conversationId);
});

final lastMessageProvider = FutureProvider.family.autoDispose<String, String>((ref, conversationId) async {
  final dataSource = ref.read(chatDataSourceProvider);
  final msgs = await dataSource.getMessages(conversationId);
  if (msgs.isNotEmpty) return msgs.first.content.isNotEmpty ? msgs.first.content : 'No messages yet';
  return 'No messages yet';
});

// 3. Provider that listens to the live WebSocket stream
final liveMessageStreamProvider = StreamProvider<dynamic>((ref) async* {
  final wsClient = ref.read(webSocketClientProvider);
  await wsClient.connect();
  
  ref.onDispose(() {
    wsClient.disconnect();
  });

  yield* wsClient.stream;
});
