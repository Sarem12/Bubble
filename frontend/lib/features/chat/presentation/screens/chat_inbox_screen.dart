import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../../shared/widgets/liquid_glass.dart';
import '../../../../shared/widgets/profile_tab_bar.dart';
import '../../../../shared/providers/dynamic_dock_provider.dart';
import '../../../../core/providers/user_cache_provider.dart';
import '../../domain/entities/conversation.dart';
import '../controllers/chat_controller.dart';
import '../controllers/activity_controller.dart';
import '../widgets/activity_tile.dart';
import '../../domain/entities/activity_item.dart';

class ChatInboxScreen extends ConsumerWidget {
  const ChatInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(liveMessageStreamProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        try {
          final dynamic raw = next.value;
          final Map<String, dynamic> payload = raw is String ? jsonDecode(raw) : (raw is Map<String, dynamic> ? raw : {});
          final convId = payload['conversation_id'] ?? (payload['message'] is Map ? payload['message']['conversation_id'] : null);
          if (convId != null) {
            ref.invalidate(lastMessageProvider(convId.toString()));
            ref.invalidate(conversationsProvider);
            ref.invalidate(chatHistoryProvider(convId.toString()));
          }
        } catch (_) {}
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: LiquidGlassAppBar(
          automaticallyImplyLeading: false,
          centerTitle: false,
          title: Text(
            'Inbox',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: -0.4,
              color: LiquidGlassTheme.textPrimary(context),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () {
                  SafeHaptics.lightImpact();
                  ref.read(dynamicDockProvider.notifier).openNewChat();
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : const Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.16)
                          : const Color(0xFFCBD5E1),
                      width: 1.1,
                    ),
                  ),
                  child: Icon(
                    PhosphorIconsRegular.notePencil,
                    size: 19,
                    color: LiquidGlassTheme.textPrimary(context),
                  ),
                ),
              ),
            ),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(52),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ProfileTabBar(
                tabs: [
                  Tab(
                    height: 36,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIconsRegular.bell, size: 15),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Activity',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    height: 36,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIconsRegular.chatCircleDots, size: 15),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Messages',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            const _ActivityTabView(),
            _MessagesTabView(
              onStartChat: () {
                SafeHaptics.lightImpact();
                ref.read(dynamicDockProvider.notifier).openNewChat();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTabView extends ConsumerStatefulWidget {
  const _ActivityTabView();

  @override
  ConsumerState<_ActivityTabView> createState() => _ActivityTabViewState();
}

class _ActivityTabViewState extends ConsumerState<_ActivityTabView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  void _acceptRequest(String userId) async {
    final success = await ref.read(activityControllerProvider.notifier).acceptRequest(userId);
    if (success && mounted) {
      UiHelpers.showSuccess(context, "Friend request accepted!");
    }
  }

  void _declineRequest(String userId) async {
    final success = await ref.read(activityControllerProvider.notifier).declineRequest(userId);
    if (success && mounted) {
      UiHelpers.showSuccess(context, "Friend request removed");
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activityAsync = ref.watch(activityControllerProvider);
    final controller = ref.read(activityControllerProvider.notifier);

    return RefreshIndicator(
      onRefresh: () => controller.refresh(),
      child: activityAsync.when(
        loading: () => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.55,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
        error: (err, stack) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.only(top: 80, left: 32, right: 32),
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 52, color: isDark ? Colors.white38 : Colors.grey[400]),
                  const SizedBox(height: 14),
                  Text(
                    'Failed to load activity',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: LiquidGlassTheme.textPrimary(context)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$err',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: LiquidGlassTheme.textSecondary(context), fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  LiquidGlassButton(
                    onPressed: () => controller.refresh(),
                    label: 'Retry',
                    height: 38,
                    isPrimary: true,
                  ),
                ],
              ),
            ),
          ],
        ),
        data: (feedData) {
          final requests = feedData.friendRequests;
          final activities = feedData.activities;

          if (requests.isEmpty && activities.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.only(top: 100, left: 32, right: 32),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.favorite_border, size: 56, color: isDark ? Colors.white38 : Colors.grey[400]),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No new activity yet',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: LiquidGlassTheme.textPrimary(context)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'When people react to your posts, reply to your comments, or send you friend requests, they will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: LiquidGlassTheme.textSecondary(context), height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              if (requests.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        'Friend Requests',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: LiquidGlassTheme.textPrimary(context)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${requests.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                ...requests.map((req) => _buildFriendRequestTile(context, req)),
                Divider(
                  height: 24,
                  thickness: 1,
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                ),
              ],
              if (activities.isNotEmpty) ...[
                if (requests.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Text(
                      'Recent Activity',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: LiquidGlassTheme.textSecondary(context)),
                    ),
                  ),
                ...activities.map((act) => ActivityTile(
                  activity: act,
                  onAcceptFriend: act.type == 'friend_request'
                      ? () => _acceptRequest(act.actorId)
                      : null,
                  onDeclineFriend: act.type == 'friend_request'
                      ? () => _declineRequest(act.actorId)
                      : null,
                )),
              ],
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFriendRequestTile(BuildContext context, FriendRequestItem req) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: GestureDetector(
        onTap: () => context.push('/user/${req.userId}'),
        child: UserAvatar(imageUrl: req.profilePictureUrl, radius: 24),
      ),
      title: GestureDetector(
        onTap: () => context.push('/user/${req.userId}'),
        child: Text(
          req.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.bold, color: LiquidGlassTheme.textPrimary(context)),
      ),
      ),
      subtitle: Text(
        '@${req.username}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: LiquidGlassTheme.textSecondary(context), fontSize: 13),
      ),
      trailing: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LiquidGlassButton(
            onPressed: () => _acceptRequest(req.userId),
            label: 'Confirm',
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            isPrimary: true,
          ),
          const SizedBox(width: 8),
          LiquidGlassButton(
            onPressed: () => _declineRequest(req.userId),
            label: 'Delete',
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            isPrimary: false,
          ),
        ],
      ),
      ),
    );
  }
}

class _MessagesTabView extends ConsumerStatefulWidget {
  final VoidCallback onStartChat;

  const _MessagesTabView({required this.onStartChat});

  @override
  ConsumerState<_MessagesTabView> createState() => _MessagesTabViewState();
}

class _MessagesTabViewState extends ConsumerState<_MessagesTabView>
    with AutomaticKeepAliveClientMixin {
  final Set<String> _selectedIds = {};
  final Map<String, String> _targetIdMap = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    // Reset dynamic dock if leaving
    if (_selectedIds.isNotEmpty) {
      ref.read(dynamicDockProvider.notifier).resetToNavigation();
    }
    super.dispose();
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
      _targetIdMap.clear();
    });
    ref.read(dynamicDockProvider.notifier).resetToNavigation();
  }

  void _toggleSelection(String convId, String targetId, List<EnrichedConversation> conversations) {
    SafeHaptics.lightImpact();
    setState(() {
      if (_selectedIds.contains(convId)) {
        _selectedIds.remove(convId);
        _targetIdMap.remove(convId);
      } else {
        _selectedIds.add(convId);
        _targetIdMap[convId] = targetId;
      }
    });

    if (_selectedIds.isEmpty) {
      ref.read(dynamicDockProvider.notifier).resetToNavigation();
    } else {
      _syncSelectionDock(conversations);
    }
  }

  void _selectAll(List<EnrichedConversation> conversations) {
    SafeHaptics.lightImpact();
    setState(() {
      for (final c in conversations) {
        _selectedIds.add(c.id);
        _targetIdMap[c.id] = c.friendId;
      }
    });
    _syncSelectionDock(conversations);
  }

  void _syncSelectionDock(List<EnrichedConversation> conversations) {
    ref.read(dynamicDockProvider.notifier).setSelectionMode(
      count: _selectedIds.length,
      title: '${_selectedIds.length} Selected',
      onCancel: _clearSelection,
      actions: [
        DynamicDockAction(
          icon: LucideIcons.bellOff,
          label: 'Mute',
          onTap: () {
            final count = _selectedIds.length;
            _clearSelection();
            UiHelpers.showSuccess(context, "Muted $count chats");
          },
        ),
        DynamicDockAction(
          icon: LucideIcons.pin,
          label: 'Pin',
          onTap: () {
            final count = _selectedIds.length;
            _clearSelection();
            UiHelpers.showSuccess(context, "Pinned $count chats");
          },
        ),
        DynamicDockAction(
          icon: LucideIcons.trash2,
          label: 'Delete',
          isDestructive: true,
          onTap: () => _confirmBatchDelete(context),
        ),
      ],
      popouts: [
        DynamicDockPopoutItem(
          icon: LucideIcons.checkCheck,
          label: 'Select All',
          onTap: () => _selectAll(conversations),
        ),
        DynamicDockPopoutItem(
          icon: LucideIcons.mailOpen,
          label: 'Mark as Read',
          onTap: () {
            final count = _selectedIds.length;
            _clearSelection();
            UiHelpers.showSuccess(context, "Marked $count as read");
          },
        ),
      ],
    );
  }

  void _confirmBatchDelete(BuildContext context) {
    final count = _selectedIds.length;
    showBubbleDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(
          'Delete $count Chat${count > 1 ? 's' : ''}?',
          style: TextStyle(fontWeight: FontWeight.bold, color: LiquidGlassTheme.textPrimary(dialogCtx)),
        ),
        content: Text(
          'Are you sure? All selected messages and chat history will be permanently deleted.',
          style: TextStyle(color: LiquidGlassTheme.textSecondary(dialogCtx)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: TextStyle(color: LiquidGlassTheme.textSecondary(dialogCtx))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final ds = ref.read(chatDataSourceProvider);
              final wsClient = ref.read(webSocketClientProvider);

              for (final entry in _targetIdMap.entries) {
                wsClient.deleteConversation(entry.key, entry.value);
                await ds.deleteConversation(entry.key);
              }

              ref.invalidate(conversationsProvider);
              if (context.mounted) {
                UiHelpers.showSuccess(context, "Deleted $count conversation${count > 1 ? 's' : ''}");
              }
              _clearSelection();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final conversationsAsync = ref.watch(conversationsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(conversationsProvider.future),
      child: conversationsAsync.when(
        loading: () => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.55,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
        error: (err, stack) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.only(top: 80, left: 32, right: 32),
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 52, color: isDark ? Colors.white38 : Colors.grey[400]),
                  const SizedBox(height: 14),
                  Text(
                    'Chat Service Offline',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: LiquidGlassTheme.textPrimary(context)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$err',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: LiquidGlassTheme.textSecondary(context), fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  LiquidGlassButton(
                    onPressed: () => ref.refresh(conversationsProvider.future),
                    label: 'Retry',
                    height: 38,
                    isPrimary: true,
                  ),
                ],
              ),
            ),
          ],
        ),
        data: (conversations) {
          if (conversations.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.only(top: 100),
                  child: Column(
                    children: [
                      Text(
                        'No active conversations yet.',
                        style: TextStyle(fontSize: 16, color: LiquidGlassTheme.textPrimary(context)),
                      ),
                      const SizedBox(height: 16),
                      LiquidGlassButton(
                        onPressed: widget.onStartChat,
                        label: 'Start Chat',
                        height: 38,
                        isPrimary: true,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          final isSelectionMode = _selectedIds.isNotEmpty;

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conv = conversations[index];
              final isSelected = _selectedIds.contains(conv.id);

              return ConversationTile(
                conversationId: conv.id,
                targetId: conv.friendId,
                lastMsg: conv.lastMessage,
                isSelectionMode: isSelectionMode,
                isSelected: isSelected,
                onToggleSelect: () => _toggleSelection(conv.id, conv.friendId, conversations),
              );
            },
          );
        },
      ),
    );
  }
}

class ConversationTile extends ConsumerWidget {
  final String conversationId;
  final String targetId;
  final String lastMsg;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onToggleSelect;

  const ConversationTile({
    super.key,
    required this.conversationId,
    required this.targetId,
    required this.lastMsg,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onToggleSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveLastMsg = ref.watch(lastMessageProvider(conversationId));
    final displayMsg = liveLastMsg.value ?? lastMsg;
    final userAsync = ref.watch(userCacheProvider(targetId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return userAsync.when(
      data: (user) => Container(
        color: isSelected
            ? (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F3F6))
            : Colors.transparent,
        child: ListTile(
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              UserAvatar(
                imageUrl: user.profilePictureUrl,
                radius: 24,
                heroTag: 'chat_avatar_$targetId',
              ),
              if (isSelected)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF181818) : Colors.white,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      LucideIcons.check,
                      size: 10,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            user.username,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: LiquidGlassTheme.textPrimary(context),
            ),
          ),
          subtitle: Text(
            displayMsg,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: LiquidGlassTheme.textSecondary(context)),
          ),
          trailing: isSelectionMode
              ? AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? (isDark ? Colors.white : const Color(0xFF0F172A))
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : (isDark ? Colors.white38 : const Color(0xFFCBD5E1)),
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          LucideIcons.check,
                          size: 14,
                          color: isDark ? Colors.black : Colors.white,
                        )
                      : null,
                )
              : IconButton(
                  icon: Icon(
                    PhosphorIconsRegular.dotsThreeVertical,
                    size: 20,
                    color: LiquidGlassTheme.textSecondary(context),
                  ),
                  onPressed: () {
                    SafeHaptics.lightImpact();
                    onToggleSelect?.call();
                  },
                ),
          onTap: () {
            if (isSelectionMode) {
              onToggleSelect?.call();
            } else {
              context.push('/inbox/chat/$conversationId?targetId=$targetId');
            }
          },
          onLongPress: () {
            SafeHaptics.mediumImpact();
            onToggleSelect?.call();
          },
        ),
      ),
      loading: () => ListTile(
        leading: const UserAvatar(radius: 24),
        title: const SizedBox(width: 100, height: 16, child: LinearProgressIndicator()),
        subtitle: Text(displayMsg, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      error: (_, _) => ListTile(
        leading: const UserAvatar(radius: 24),
        title: Text(
          'Unknown',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: LiquidGlassTheme.textPrimary(context),
          ),
        ),
        subtitle: Text(displayMsg, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
