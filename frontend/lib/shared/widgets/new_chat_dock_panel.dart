import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/routes.dart';
import '../../core/utils/ui_helpers.dart';
import '../../features/chat/presentation/controllers/chat_controller.dart';
import '../../features/chat/data/datasources/chat_remote_datasource.dart';
import '../../features/profile/data/datasources/friend_remote_datasource.dart';
import '../providers/dynamic_dock_provider.dart';
import 'liquid_glass.dart';
import 'user_avatar.dart';


/// Full Morphing New Chat / Friends Picker Panel embedded inside the Dynamic Liquid Dock
class NewChatDockPanel extends ConsumerStatefulWidget {
  final VoidCallback? onClose;

  const NewChatDockPanel({
    super.key,
    this.onClose,
  });

  @override
  ConsumerState<NewChatDockPanel> createState() => _NewChatDockPanelState();
}

class _NewChatDockPanelState extends ConsumerState<NewChatDockPanel> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _friends = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _fetchFriends();
    _searchController.addListener(() {
      final query = _searchController.text.trim().toLowerCase();
      if (query != _searchQuery) {
        setState(() {
          _searchQuery = query;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchFriends() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rawList = await ref.read(friendRemoteDataSourceProvider).getFriends();
      if (mounted) {
        setState(() {
          _friends = rawList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Failed to load friends.";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startChat(String friendId) async {
    if (friendId.isEmpty) return;
    SafeHaptics.mediumImpact();

    try {
      final res = await ref.read(chatRemoteDataSourceProvider).createConversation(friendId);
      final convId = res['id'];
      ref.invalidate(conversationsProvider);
      ref.read(dynamicDockProvider.notifier).resetToNavigation();
      appRouter.push('/inbox/chat/$convId?targetId=$friendId');
    } catch (e) {
      debugPrint("Failed to start chat: $e");
      if (mounted) {
        UiHelpers.showError(context, "Could not start chat");
      }
    }
  }

  void _handleClose() {
    SafeHaptics.lightImpact();
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      ref.read(dynamicDockProvider.notifier).resetToNavigation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredFriends = _friends.where((f) {
      if (_searchQuery.isEmpty) return true;
      final username = (f['friend_username'] ?? f['username'] ?? '').toString().toLowerCase();
      return username.contains(_searchQuery);
    }).toList();

    return Column(
      children: [
        // 1. Top Drag Handle
        const SizedBox(height: 10),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // 2. Header (Title, Friend Count Badge, Close Button)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                PhosphorIconsRegular.chatCircleDots,
                size: 20,
                color: LiquidGlassTheme.textPrimary(context),
              ),
              const SizedBox(width: 8),
              Text(
                "New Chat",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  letterSpacing: -0.2,
                  color: LiquidGlassTheme.textPrimary(context),
                ),
              ),
              const SizedBox(width: 8),
              if (_friends.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.16) : const Color(0xFFCBD5E1),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    "${_friends.length}",
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: LiquidGlassTheme.textPrimary(context),
                    ),
                  ),
                ),
              const Spacer(),
              GestureDetector(
                onTap: _handleClose,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.x,
                    size: 16,
                    color: LiquidGlassTheme.textPrimary(context),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 3. Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F3F6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIconsRegular.magnifyingGlass,
                  size: 17,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: LiquidGlassTheme.textPrimary(context),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search friends...',
                      hintStyle: TextStyle(
                        fontSize: 13.5,
                        color: LiquidGlassTheme.textSecondary(context),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(
                        LucideIcons.xCircle,
                        size: 16,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        Divider(
          height: 1,
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),

        // 4. Friends List Body
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.alertCircle,
                              size: 40,
                              color: Colors.redAccent.withValues(alpha: 0.8),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _error!,
                              style: TextStyle(
                                fontSize: 14,
                                color: LiquidGlassTheme.textSecondary(context),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _fetchFriends,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _friends.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F3F6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    PhosphorIconsRegular.users,
                                    size: 28,
                                    color: LiquidGlassTheme.textSecondary(context),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  "No friends yet",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: LiquidGlassTheme.textPrimary(context),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Connect with people on Bubble to start conversations.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: LiquidGlassTheme.textSecondary(context),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : filteredFriends.isEmpty
                          ? Center(
                              child: Text(
                                "No friends matching '$_searchQuery'",
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: LiquidGlassTheme.textSecondary(context),
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredFriends.length,
                              padding: const EdgeInsets.fromLTRB(0, 6, 0, 16),
                              itemBuilder: (context, index) {
                                final f = filteredFriends[index];
                                final friendUsername = (f['friend_username'] ?? f['username'] ?? 'Unknown').toString();
                                final friendId = (f['friend_id'] ?? f['user_id'] ?? f['target_user_id'] ?? '').toString();
                                final friendAvatar = (f['friend_avatar'] ?? f['avatar'] ?? f['profile_picture_url'] ?? '').toString();
                                final isBestFriend = f['is_bestfriend'] == true;

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
                                  leading: UserAvatar(
                                    imageUrl: friendAvatar,
                                    radius: 22,
                                    heroTag: friendId.isNotEmpty ? 'chat_avatar_$friendId' : null,
                                  ),
                                  title: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          friendUsername,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                            color: LiquidGlassTheme.textPrimary(context),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isBestFriend) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withValues(alpha: 0.18),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(PhosphorIconsFill.star, size: 10, color: Colors.amber),
                                              SizedBox(width: 2),
                                              Text(
                                                'Bestie',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.amber,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  subtitle: Text(
                                    '@$friendUsername',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: LiquidGlassTheme.textSecondary(context),
                                    ),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFF1F3F6),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark ? Colors.white.withValues(alpha: 0.16) : const Color(0xFFCBD5E1),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          PhosphorIconsRegular.chatTeardropDots,
                                          size: 15,
                                          color: LiquidGlassTheme.textPrimary(context),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Chat',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: LiquidGlassTheme.textPrimary(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  onTap: () => _startChat(friendId),
                                );
                              },
                            ),
        ),
      ],
    );
  }
}
