import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../../core/utils/safe_haptics.dart';
import '../controllers/active_chat_controller.dart';
import '../controllers/chat_controller.dart';
import '../../../../core/providers/user_cache_provider.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../../shared/widgets/smart_user_avatar.dart';
import '../../../../shared/widgets/liquid_glass.dart';
import '../../domain/entities/message.dart';
import '../../../../features/profile/presentation/controllers/profile_controller.dart';
import '../../../../features/profile/presentation/controllers/settings_controller.dart';
import '../../../../core/network/websocket_client.dart';
import '../../../../shared/emoji/emoji.dart';

class ActiveChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String? targetId;

  const ActiveChatScreen({
    super.key,
    required this.conversationId,
    this.targetId,
  });

  @override
  ConsumerState<ActiveChatScreen> createState() => _ActiveChatScreenState();
}

class _ActiveChatScreenState extends ConsumerState<ActiveChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // Message selection & emoji picker morphing dock states
  Message? _selectedMessage;
  bool _isEmojiPickerOpen = false;

  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final controller = ref.read(
        activeChatControllerProvider(widget.conversationId).notifier,
      );
      if (widget.targetId != null) {
        controller.markAsRead(widget.targetId!);
        controller.startPresenceTracking(widget.targetId);
      }
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    if (!_isTyping && text.isNotEmpty) {
      _isTyping = true;
      _sendTypingEvent();
      _typingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (_msgController.text.isNotEmpty) {
          _sendTypingEvent();
        } else {
          _isTyping = false;
          _typingTimer?.cancel();
        }
      });
    } else if (_isTyping && text.isEmpty) {
      _isTyping = false;
      _typingTimer?.cancel();
    }
  }

  void _sendTypingEvent() {
    if (widget.targetId != null) {
      ref
          .read(activeChatControllerProvider(widget.conversationId).notifier)
          .sendTyping(widget.targetId!);
    }
  }

  void _toggleReaction(Message msg, String emoji) {
    final profileAsync = ref.read(profileControllerProvider);
    final myId = (profileAsync.value?['id'] ?? '').toString();

    ref
        .read(activeChatControllerProvider(widget.conversationId).notifier)
        .toggleReaction(msg, emoji, widget.targetId ?? '', myId);
  }

  Future<void> _confirmDeleteMessage(Message msg) async {
    final confirmed = await showBubbleConfirmDialog(
      context: context,
      title: 'Delete Message',
      message: 'Are you sure you want to delete this message?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed == true) {
      _deleteMessage(msg);
    }
  }

  void _deleteMessage(Message msg) {
    ref
        .read(activeChatControllerProvider(widget.conversationId).notifier)
        .deleteMessage(msg, widget.targetId ?? '');
    ref.invalidate(conversationsProvider);
  }

  Future<void> _confirmDeleteConversation() async {
    final confirmed = await showBubbleConfirmDialog(
      context: context,
      title: 'Delete Conversation',
      message:
          'Are you sure you want to delete this conversation and all its messages? This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed == true) {
      await _deleteConversation();
    }
  }

  Future<void> _deleteConversation() async {
    await ref
        .read(activeChatControllerProvider(widget.conversationId).notifier)
        .deleteConversation(widget.targetId ?? '');
    ref.invalidate(conversationsProvider);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Conversation deleted')));
    }
  }

  void _selectMessage(Message msg) {
    SafeHaptics.mediumImpact();
    _focusNode.unfocus();
    setState(() {
      if (_selectedMessage?.id == msg.id && !_isEmojiPickerOpen) {
        _selectedMessage = null;
        _isEmojiPickerOpen = false;
      } else {
        _selectedMessage = msg;
        _isEmojiPickerOpen = false;
      }
    });
  }

  void _clearSelection() {
    if (_selectedMessage != null || _isEmojiPickerOpen) {
      setState(() {
        _selectedMessage = null;
        _isEmojiPickerOpen = false;
      });
    }
  }

  void _copySelectedMessage() {
    if (_selectedMessage == null) return;
    Clipboard.setData(ClipboardData(text: _selectedMessage!.content));
    SafeHaptics.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
    _clearSelection();
  }

  void _deleteSelectedMessage() {
    if (_selectedMessage == null) return;
    final msg = _selectedMessage!;
    _confirmDeleteMessage(msg);
    _clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(
      activeChatControllerProvider(widget.conversationId),
    );
    final profileAsync = ref.watch(profileControllerProvider);
    final myId = (profileAsync.value?['id'] ?? '').toString();

    final targetUserAsync = widget.targetId != null
        ? ref.watch(userCacheProvider(widget.targetId!))
        : null;
    final targetUser = targetUserAsync?.value;

    final wsStatusAsync = ref.watch(wsStatusProvider);
    final wsStatus = wsStatusAsync.value ?? ConnectionStateStatus.connecting;

    final chatState = chatAsync.value;
    final messages = chatState?.messages ?? const [];
    final isFriendOnline = chatState?.isFriendOnline ?? false;
    final isFriendTyping = chatState?.isFriendTyping ?? false;
    final lastActiveText = (chatState?.lastActiveText.isNotEmpty == true)
        ? chatState!.lastActiveText
        : (targetUser?.lastActiveFormatted ?? '');

    final chatTitle =
        targetUser?.displayName ??
        (widget.targetId == null ? 'Chat' : 'Loading...');
    final friendAvatar = targetUser?.profilePictureUrl ?? '';

    // Listen for conversation deletion
    ref.listen(activeChatControllerProvider(widget.conversationId), (
      previous,
      next,
    ) {
      if (next.value?.isConversationDeleted == true &&
          previous?.value?.isConversationDeleted != true) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This conversation was deleted')),
          );
        }
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topInset = MediaQuery.paddingOf(context).top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: LiquidGlassAppBar(
        automaticallyImplyLeading: false,
        leading: const BubbleBackButton(),
        title: Row(
          children: [
            if (friendAvatar.isNotEmpty) ...[
              Stack(
                children: [
                  UserAvatar(
                    imageUrl: friendAvatar,
                    radius: 18,
                    heroTag: widget.targetId != null
                        ? 'chat_avatar_${widget.targetId}'
                        : null,
                  ),
                  if (wsStatus == ConnectionStateStatus.connected &&
                      isFriendOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF1C1C1C)
                                : Colors.white,
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(color: Color(0xFF10B981), blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    chatTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: LiquidGlassTheme.textPrimary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (wsStatus == ConnectionStateStatus.noNetwork)
                    const Text(
                      'No connection',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.orange),
                    )
                  else if (wsStatus == ConnectionStateStatus.connecting)
                    Text(
                      'Connecting...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: LiquidGlassTheme.textSecondary(context),
                      ),
                    )
                  else if (isFriendTyping)
                    Text(
                      'typing...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else if (isFriendOnline)
                    const Text(
                      'Online',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else if (lastActiveText.isNotEmpty)
                    Text(
                      lastActiveText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: LiquidGlassTheme.textSecondary(context),
                      ),
                    )
                  else
                    Text(
                      'Offline',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: LiquidGlassTheme.textSecondary(context),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              PhosphorIconsRegular.dotsThreeVertical,
              color: LiquidGlassTheme.textPrimary(context),
              size: 20,
            ),
            onSelected: (value) {
              if (value == 'block') {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('User blocked')));
              } else if (value == 'delete_chat') {
                _confirmDeleteConversation();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: 'block',
                  child: Text(
                    'Block User',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete_chat',
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIconsRegular.trash,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Delete Chat',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _clearSelection,
              behavior: HitTestBehavior.opaque,
              child: (chatAsync.isLoading && messages.isEmpty)
                  ? const Center(child: CircularProgressIndicator())
                  : (chatAsync.hasError && messages.isEmpty)
                  ? Center(
                      child: Text('Error loading messages: ${chatAsync.error}'),
                    )
                      : messages.isEmpty
                          ? Center(
                              child: Text(
                                'Say hi!',
                        style: TextStyle(
                          color: LiquidGlassTheme.textSecondary(context),
                        ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              reverse: true,
                              padding: EdgeInsets.only(top: topInset + 12, bottom: 8),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final msg = messages[index];
                                final isMe = msg.senderId == myId;
                                final isSelected = _selectedMessage?.id == msg.id;

                                // Group reactions by emoji
                                final Map<String, int> reactionCounts = {};
                                for (final r in msg.reactions) {
                          reactionCounts[r.emoji] =
                              (reactionCounts[r.emoji] ?? 0) + 1;
                                }

                                final bubbleContent = Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg.content,
                                      style: TextStyle(
                                color: isMe
                                    ? LiquidGlassTheme.primaryTextColor(context)
                                    : LiquidGlassTheme.textPrimary(context),
                                        fontSize: 14,
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${msg.createdAt.hour}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            color: isMe
                                        ? LiquidGlassTheme.primaryTextColor(
                                            context,
                                          ).withValues(alpha: 0.65)
                                        : LiquidGlassTheme.textSecondary(
                                            context,
                                          ),
                                            fontSize: 10,
                                          ),
                                        ),
                                        if (isMe) ...[
                                          const SizedBox(width: 4),
                                          if (msg.isOptimistic)
                                    Icon(
                                      PhosphorIconsRegular.clock,
                                      color: LiquidGlassTheme.primaryTextColor(
                                        context,
                                      ).withValues(alpha: 0.6),
                                      size: 12,
                                    )
                                          else if (msg.readAt != null)
                                    Icon(
                                      PhosphorIconsFill.checks,
                                      color: LiquidGlassTheme.primaryTextColor(
                                        context,
                                      ),
                                      size: 14,
                                    )
                                          else
                                    Icon(
                                      PhosphorIconsRegular.check,
                                      color: LiquidGlassTheme.primaryTextColor(
                                        context,
                                      ).withValues(alpha: 0.7),
                                      size: 13,
                                    ),
                                        ],
                                      ],
                                    ),
                                    if (msg.reactions.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                        children: reactionCounts.entries.map((entry) {
                                  final hasMyReaction = msg.reactions.any(
                                    (r) =>
                                        r.emoji == entry.key &&
                                        r.userId == myId,
                                  );
                                          return GestureDetector(
                                    onTap: () =>
                                        _toggleReaction(msg, entry.key),
                                            child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                              decoration: BoxDecoration(
                                                color: isMe
                                                    ? (hasMyReaction
                                                  ? Colors.white.withValues(
                                                      alpha: 0.25,
                                                    )
                                                  : Colors.black.withValues(
                                                      alpha: 0.25,
                                                    ))
                                                    : (isDark
                                                        ? (hasMyReaction
                                                        ? Colors.white
                                                              .withValues(
                                                                alpha: 0.22,
                                                              )
                                                        : Colors.white
                                                              .withValues(
                                                                alpha: 0.08,
                                                              ))
                                                        : (hasMyReaction
                                                        ? const Color(
                                                            0xFFE2E8F0,
                                                          )
                                                        : const Color(
                                                            0xFFF1F3F6,
                                                          ))),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: isMe
                                              ? (hasMyReaction
                                                    ? Colors.white
                                                    : Colors.white24)
                                                      : (isDark
                                                    ? (hasMyReaction
                                                          ? Colors.white
                                                          : Colors.white24)
                                                    : (hasMyReaction
                                                          ? const Color(
                                                              0xFF94A3B8,
                                                            )
                                                          : const Color(
                                                              0xFFCBD5E1,
                                                            ))),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                          AppEmoji(
                                            emoji: entry.key,
                                            size: 14,
                                            animate: true,
                                          ),
                                                  if (entry.value > 1) ...[
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      '${entry.value}',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                color: isMe || isDark
                                                    ? Colors.white
                                                    : const Color(0xFF111827),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ],
                                );

                                return GestureDetector(
                                  onTap: () {
                                    if (_selectedMessage != null) {
                                      _selectMessage(msg);
                                    }
                                  },
                                  onLongPress: () => _selectMessage(msg),
                                  child: Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                                    child: Row(
                              mainAxisAlignment: isMe
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        if (!isMe) ...[
                                          const SizedBox(width: 14),
                                  SmartUserAvatar(
                                    userId: msg.senderId,
                                    radius: 14,
                                  ),
                                        ],
                                Flexible(
                                  child: isMe
                                            ? Container(
                                          margin: const EdgeInsets.only(
                                            top: 4,
                                            bottom: 4,
                                            left: 60,
                                            right: 16,
                                          ),
                                                child: LiquidContinuousChatBubble(
                                            borderRadius:
                                                const BorderRadius.only(
                                                    topLeft: Radius.circular(20),
                                                    topRight: Radius.circular(20),
                                                  bottomLeft: Radius.circular(
                                                    20,
                                                  ),
                                                  bottomRight: Radius.circular(
                                                    4,
                                                  ),
                                                  ),
                                                  isSelected: isSelected,
                                                  isDark: isDark,
                                                  scrollController: _scrollController,
                                                  child: bubbleContent,
                                                ),
                                              )
                                            : Container(
                                          margin: const EdgeInsets.only(
                                            top: 4,
                                            bottom: 4,
                                            left: 8,
                                            right: 60,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: isDark
                                                        ? [
                                                      const Color(
                                                        0xFF1C1C1C,
                                                      ).withValues(alpha: 0.85),
                                                      const Color(
                                                        0xFF121212,
                                                      ).withValues(alpha: 0.75),
                                                          ]
                                                        : [
                                                      Colors.white.withValues(
                                                        alpha: 0.95,
                                                      ),
                                                      const Color(
                                                        0xFFF4F4F5,
                                                      ).withValues(alpha: 0.85),
                                                          ],
                                                  ),
                                            borderRadius:
                                                const BorderRadius.only(
                                                    topLeft: Radius.circular(20),
                                                    topRight: Radius.circular(20),
                                                  bottomLeft: Radius.circular(
                                                    4,
                                                  ),
                                                  bottomRight: Radius.circular(
                                                    20,
                                                  ),
                                                  ),
                                                  border: Border.all(
                                                    color: isSelected
                                                  ? Theme.of(
                                                      context,
                                                    ).colorScheme.primary
                                                        : (isDark
                                                        ? Colors.white
                                                              .withValues(
                                                                alpha: 0.16,
                                                              )
                                                        : const Color(
                                                            0xFFE2E8F0,
                                                          )),
                                                    width: isSelected ? 2.0 : 1.1,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: isSelected
                                                    ? Theme.of(context)
                                                          .colorScheme
                                                          .primary
                                                          .withValues(
                                                            alpha: 0.30,
                                                          )
                                                    : Colors.black.withValues(
                                                        alpha: isDark
                                                            ? 0.25
                                                            : 0.05,
                                                      ),
                                                blurRadius: isSelected
                                                    ? 12
                                                    : 10,
                                                      offset: const Offset(0, 3),
                                                    ),
                                                  ],
                                                ),
                                                child: bubbleContent,
                                              ),
                                ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ),

          // Pure Fluid Morphing Dynamic Liquid Dock
          _buildBottomDock(isDark, myId),
        ],
      ),
    );
  }

  /// Pure Fluid Morphing Dynamic Liquid Dock
  Widget _buildBottomDock(bool isDark, String myId) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final double bottomMargin = keyboardInset > 0
        ? keyboardInset + 8
        : (bottomPadding > 0 ? bottomPadding : 16.0);
    final EdgeInsets dockPadding = EdgeInsets.fromLTRB(16, 0, 16, bottomMargin);

    // Single unified morphing height: 380px (emoji picker), 118px (reactions & selection), 60px (input)
    final double barHeight = _isEmojiPickerOpen
        ? 380.0
        : (_selectedMessage != null ? 118.0 : 60.0);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      padding: dockPadding,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        height: barHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.12),
              blurRadius: _isEmojiPickerOpen ? 28 : 22,
              offset: const Offset(0, 6),
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: barHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(
                            0xFF1C1C1C,
                          ).withValues(alpha: _isEmojiPickerOpen ? 0.95 : 0.92),
                          const Color(
                            0xFF101010,
                          ).withValues(alpha: _isEmojiPickerOpen ? 0.93 : 0.88),
                        ]
                      : [
                          Colors.white.withValues(
                            alpha: _isEmojiPickerOpen ? 0.96 : 0.92,
                          ),
                          const Color(
                            0xFFF8F9FA,
                          ).withValues(alpha: _isEmojiPickerOpen ? 0.94 : 0.88),
                        ],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : const Color(0xFFCBD5E1),
                  width: 1.2,
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.bottomCenter,
                    children: <Widget>[...previousChildren, ?currentChild],
                  );
                },
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: _isEmojiPickerOpen
                    ? _buildExpandedEmojiDock(isDark)
                    : (_selectedMessage != null
                        ? _buildSelectionAndReactionDock(isDark, myId)
                        : _buildInputDockContent(isDark)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Morph Mode 1: Normal Chat Input Dock (60px)
  Widget _buildInputDockContent(bool isDark) {
    return Container(
      key: const ValueKey('chat_input_mode'),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              SafeHaptics.lightImpact();
              _focusNode.unfocus();
              setState(() => _isEmojiPickerOpen = true);
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIconsRegular.smiley,
                color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFF1F3F6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _msgController,
                focusNode: _focusNode,
                onChanged: _onTextChanged,
                onTap: () {
                  if (_isEmojiPickerOpen) {
                    setState(() => _isEmojiPickerOpen = false);
                  }
                },
                style: TextStyle(
                  fontSize: 14,
                  color: LiquidGlassTheme.textPrimary(context),
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: LiquidGlassTheme.textSecondary(context),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 6),
          LiquidGlassIconButton(
            icon: PhosphorIconsFill.paperPlaneTilt,
            size: 38,
            onPressed: _sendMessage,
            tooltip: 'Send message',
          ),
        ],
      ),
    );
  }

  /// Morph Mode 2: In-Dock Message Selection & Animated Reactions (118px)
  Widget _buildSelectionAndReactionDock(bool isDark, String myId) {
    final isMe = _selectedMessage?.senderId == myId;
    final savedReactions = ref
        .watch(settingsControllerProvider)
        .value
        ?.topReactions;
    final reactions = savedReactions == null || savedReactions.isEmpty
        ? const ['❤️', '😂', '🔥', '👍', '😮']
        : savedReactions;

    return Container(
      key: ValueKey('chat_reaction_dock_${_selectedMessage?.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: 0,
          maxHeight: 118.0,
          child: SizedBox(
            height: 118.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Top Reaction Row (Live Animated Emojis)
          SizedBox(
            height: 44,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ...reactions.map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      SafeHaptics.mediumImpact();
                      if (_selectedMessage != null) {
                        _toggleReaction(_selectedMessage!, emoji);
                      }
                      _clearSelection();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFF1F3F6),
                      ),
                      child: AppEmoji(
                        emoji: emoji,
                        size: 26,
                        animate: true,
                        enableTapAnimation: true,
                      ),
                    ),
                  );
                }),
                // Plus "+" Button: morphs dock into full animated emoji picker!
                GestureDetector(
                  onTap: () {
                    SafeHaptics.lightImpact();
                    setState(() => _isEmojiPickerOpen = true);
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : const Color(0xFFE2E8F0),
                    ),
                    child: Icon(
                      PhosphorIconsRegular.plus,
                      size: 18,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Subtle Frosted Glass Divider
          Container(
            height: 1,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : const Color(0xFFE2E8F0),
          ),

          // 3. Bottom Contextual Actions Row
          SizedBox(
            height: 42,
            child: Row(
              children: [
                // Cancel Selection (✕)
                GestureDetector(
                  onTap: _clearSelection,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : const Color(0xFFE2E8F0),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PhosphorIconsRegular.x,
                      size: 17,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Selected Title
                Expanded(
                  child: Text(
                    '1 Message Selected',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: LiquidGlassTheme.textPrimary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Copy Action
                GestureDetector(
                  onTap: _copySelectedMessage,
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : const Color(0xFFF1F3F6),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: isDark
                            ? Colors.transparent
                            : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIconsRegular.copy,
                          size: 15,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Copy',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Delete Action (if my message)
                if (isMe) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _deleteSelectedMessage,
                    child: Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(
                                alpha: isDark ? 0.18 : 0.10,
                              ),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIconsRegular.trash,
                            size: 15,
                            color: Colors.redAccent,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
          ),
        ),
      ),
    );
  }

  /// Morph Mode 3: Morphing Expanded Animated Emoji Picker (380px)
  Widget _buildExpandedEmojiDock(bool isDark) {
    return Container(
      key: const ValueKey('chat_expanded_emoji_dock'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: 0,
          maxHeight: 380.0,
          child: SizedBox(
            height: 380.0,
      child: Column(
        children: [
          // Top bar with header and collapse down-caret / close
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    SafeHaptics.lightImpact();
                    setState(() => _isEmojiPickerOpen = false);
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : const Color(0xFFE2E8F0),
                    ),
                    child: Icon(
                      PhosphorIconsRegular.caretDown,
                      size: 18,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                        _selectedMessage != null
                            ? 'React with Emoji'
                            : 'Animated Emojis',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: LiquidGlassTheme.textPrimary(context),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    SafeHaptics.lightImpact();
                    setState(() {
                      _isEmojiPickerOpen = false;
                      _selectedMessage = null;
                    });
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : const Color(0xFFE2E8F0),
                    ),
                    child: Icon(
                      PhosphorIconsRegular.x,
                      size: 16,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Live Animated Emoji Picker inside the morphed dock!
          Expanded(
            child: BubbleEmojiPicker(
              height: 320,
              initialCategory: EmojiCategory.system,
              onEmojiSelected: (emoji) {
                SafeHaptics.mediumImpact();
                if (_selectedMessage != null) {
                  _toggleReaction(_selectedMessage!, emoji.code);
                  _clearSelection();
                } else {
                  _msgController.text += emoji.code;
                  _onTextChanged(_msgController.text);
                }
              },
            ),
          ),
        ],
      ),
          ),
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final profileAsync = ref.read(profileControllerProvider);
    final myId = (profileAsync.value?['id'] ?? '').toString();

    ref
        .read(activeChatControllerProvider(widget.conversationId).notifier)
        .sendMessage(text: text, myId: myId, targetId: widget.targetId);

    _msgController.clear();
    _isTyping = false;
    _typingTimer?.cancel();
  }
}
