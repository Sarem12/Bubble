import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../shared/widgets/liquid_glass.dart';
import '../../../../shared/widgets/profile_tab_bar.dart';
import '../../../chat/data/repositories/chat_repository_impl.dart';
import '../../../home/data/repositories/post_repository_impl.dart';
import '../../../home/domain/entities/post.dart';
import '../../../search/domain/entities/bubble.dart';
import '../../domain/entities/friendship.dart';
import '../../domain/entities/user_profile.dart';
import '../../data/datasources/friend_remote_datasource.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_bubbles_tab.dart';
import '../widgets/profile_friends_tab.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_posts_grid.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _posts = [];
  List<dynamic> _friends = [];
  List<dynamic> _bubbles = [];
  bool _tabsLoading = true;
  bool _isFetchingTabs = false;
  String? _fetchedUserId;

  // State when viewing another user's profile
  UserProfile? _otherProfile;
  bool _isOtherLoading = false;
  bool _otherHasError = false;
  bool _isFriend = false;

  bool _isSelfUser(UserProfile? myProfile) {
    if (widget.userId == null ||
        widget.userId!.trim().isEmpty ||
        widget.userId == 'me') {
      return true;
    }
    if (myProfile != null && myProfile.id == widget.userId) {
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    final targetId = widget.userId?.trim();
    if (targetId != null && targetId.isNotEmpty && targetId != 'me') {
      final myProfile = ref.read(profileControllerProvider).value;
      if (myProfile == null || myProfile.id != targetId) {
        _fetchOtherUserData(targetId);
      }
    }
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _fetchedUserId = null;
      _tabsLoading = true;
      final targetId = widget.userId?.trim();
      if (targetId != null && targetId.isNotEmpty && targetId != 'me') {
        final myProfile = ref.read(profileControllerProvider).value;
        if (myProfile == null || myProfile.id != targetId) {
          _fetchOtherUserData(targetId);
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchOtherUserData(String targetId) async {
    if (_isOtherLoading) return;
    setState(() {
      _isOtherLoading = true;
      _otherHasError = false;
      _tabsLoading = true;
    });

    try {
      final profileRepo = ref.read(profileRepositoryProvider);
      final postRepo = ref.read(postRepositoryProvider);

      final profileFuture = profileRepo.getUserProfile(targetId);
      final feedFuture = postRepo.getUserPosts(targetId).catchError((e, s) => <FeedItem>[]);
      final bubblesFuture = profileRepo.getUserBubbles(targetId).catchError((e, s) => <Bubble>[]);
      final friendsFuture = profileRepo.getFriends().catchError((e, s) => <FriendUser>[]);

      final profileRes = await profileFuture;
      final results = await Future.wait([feedFuture, bubblesFuture, friendsFuture]);

      final postsList = results[0];
      final bubblesList = results[1];
      final friendsList = results[2];

      final friendStatus = (friendsList as List<FriendUser>).any((f) => f.id == targetId);

      if (mounted) {
        setState(() {
          _otherProfile = profileRes;
          _posts = postsList;
          _bubbles = bubblesList;
          _isFriend = friendStatus;
          _isOtherLoading = false;
          _tabsLoading = false;
          _fetchedUserId = targetId;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOtherLoading = false;
          _otherHasError = true;
          _tabsLoading = false;
        });
      }
    }
  }

  Future<void> _fetchSelfTabData(String myId) async {
    if (myId.isEmpty) {
      if (mounted) {
        setState(() {
          _tabsLoading = false;
          _fetchedUserId = myId;
        });
      }
      return;
    }
    if (_isFetchingTabs || _fetchedUserId == myId) return;
    _isFetchingTabs = true;
    _fetchedUserId = myId;

    try {
      final postsFuture = ref.read(postRepositoryProvider).getUserPosts(myId).catchError((e, s) => <FeedItem>[]);
      final friendsFuture = ref.read(profileRepositoryProvider).getFriends().catchError((e, s) => <FriendUser>[]);
      final bubblesFuture = ref.read(profileRepositoryProvider).getUserBubbles(myId).catchError((e, s) => <Bubble>[]);

      final results = await Future.wait([postsFuture, friendsFuture, bubblesFuture]);
      if (mounted) {
        setState(() {
          _posts = results[0];
          _friends = results[1];
          _bubbles = results[2];
          _tabsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _tabsLoading = false);
      }
    } finally {
      _isFetchingTabs = false;
    }
  }

  Future<void> _toggleFriend(String targetId) async {
    final profileRepo = ref.read(profileRepositoryProvider);
    try {
      if (_isFriend) {
        await profileRepo.removeFriend(targetId);
        if (mounted) {
          setState(() => _isFriend = false);
          ref.invalidate(friendsListProvider);
          UiHelpers.showSuccess(context, 'Friend removed');
        }
      } else {
        await profileRepo.sendFriendRequest(targetId);
        if (mounted) {
          setState(() => _isFriend = true);
          ref.invalidate(friendsListProvider);
          UiHelpers.showSuccess(context, 'Friend request sent');
        }
      }
    } catch (e) {
      if (mounted) {
        UiHelpers.showError(context, 'Operation failed');
      }
    }
  }

  void _startChat(String targetId) async {
    try {
      final chatRepo = ref.read(chatRepositoryProvider);
      final res = await chatRepo.createConversation(targetId);
      final convId = (res['id'] ?? '').toString();
      if (mounted && convId.isNotEmpty) {
        context.push('/chat/$convId?targetId=$targetId');
      }
    } catch (e) {
      if (mounted) {
        UiHelpers.showError(context, 'Could not start chat');
      }
    }
  }

  Future<void> _blockUser(String targetId) async {
    try {
      await ref.read(profileRepositoryProvider).blockUser(targetId);
      ref.invalidate(friendsListProvider);
      if (mounted) {
        UiHelpers.showSuccess(context, 'User blocked');
        if (context.canPop()) {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        UiHelpers.showError(context, 'Failed to block user');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final myProfileAsync = ref.watch(profileControllerProvider);
    final myProfile = myProfileAsync.value;
    final isMe = _isSelfUser(myProfile);

    if (isMe) {
      return myProfileAsync.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => Scaffold(
          appBar: LiquidGlassAppBar(
            automaticallyImplyLeading: context.canPop(),
            title: const Text('Profile'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Could not connect to the server'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _fetchedUserId = null;
                    _isFetchingTabs = false;
                    ref.read(profileControllerProvider.notifier).refresh();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (profile) {
          if (_fetchedUserId != profile.id && !_isFetchingTabs) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _fetchSelfTabData(profile.id);
            });
          }

          return _buildProfileScaffold(
            context: context,
            profile: profile,
            isMe: true,
          );
        },
      );
    }

    // Viewing another user
    if (_isOtherLoading && _otherProfile == null) {
      return Scaffold(
        appBar: LiquidGlassAppBar(
          automaticallyImplyLeading: context.canPop(),
          title: const Text('Profile'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_otherHasError || _otherProfile == null) {
      return Scaffold(
        appBar: LiquidGlassAppBar(
          automaticallyImplyLeading: context.canPop(),
          title: const Text('Profile'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to load profile'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (widget.userId != null) {
                    _fetchOtherUserData(widget.userId!);
                  }
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return _buildProfileScaffold(
      context: context,
      profile: _otherProfile!,
      isMe: false,
    );
  }

  Widget _buildProfileScaffold({
    required BuildContext context,
    required UserProfile profile,
    required bool isMe,
  }) {
    return Scaffold(
      appBar: LiquidGlassAppBar(
        automaticallyImplyLeading: context.canPop(),
        centerTitle: false,
        title: Text(
          profile.username,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.4,
            color: LiquidGlassTheme.textPrimary(context),
          ),
        ),
        actions: [
          if (isMe) ...[
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                tooltip: 'Create a Bubble',
                onPressed: () async {
                  await context.push('/profile/bubble/create');
                  ref.read(profileControllerProvider.notifier).refresh();
                  _fetchedUserId = null;
                  if (mounted) _fetchSelfTabData(profile.id);
                },
                icon: Icon(
                  PhosphorIconsRegular.plusCircle,
                  size: 24,
                  color: LiquidGlassTheme.textPrimary(context),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: 'Settings',
                onPressed: () => context.push('/profile/settings'),
                icon: Icon(
                  PhosphorIconsRegular.gear,
                  size: 22,
                  color: LiquidGlassTheme.textPrimary(context),
                ),
              ),
            ),
          ]
          else
            PopupMenuButton<String>(
              icon: Icon(
                PhosphorIconsRegular.dotsThreeVertical,
                color: LiquidGlassTheme.textPrimary(context),
              ),
              onSelected: (val) {
                if (val == 'block') {
                  _blockUser(profile.id);
                } else if (val == 'mute') {
                  UiHelpers.showSuccess(context, 'User muted');
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      Icon(Icons.block, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Block User', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'mute',
                  child: Row(
                    children: [
                      Icon(Icons.volume_off, size: 20),
                      SizedBox(width: 8),
                      Text('Mute User'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: ProfileHeader(
                user: profile,
                isMe: isMe,
                isFriend: _isFriend,
                onEditProfile: isMe
                    ? () async {
                        await context.push('/profile/edit');
                        ref.read(profileControllerProvider.notifier).refresh();
                        _fetchedUserId = null;
                        if (mounted) _fetchSelfTabData(profile.id);
                      }
                    : null,
                onToggleFriend: isMe ? null : () => _toggleFriend(profile.id),
                onMessage: isMe ? null : () => _startChat(profile.id),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: ProfileSliverTabBarDelegate(
                height: 56.0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ProfileTabBar(
                    controller: _tabController,
                    tabs: isMe
                        ? const [
                            Tab(
                              height: 36,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(PhosphorIconsRegular.squaresFour, size: 15),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text('Posts', maxLines: 1, overflow: TextOverflow.ellipsis),
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
                                  Icon(PhosphorIconsRegular.users, size: 15),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text('Friends', maxLines: 1, overflow: TextOverflow.ellipsis),
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
                                  Icon(PhosphorIconsRegular.circlesThree, size: 15),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text('Bubbles', maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ),
                          ]
                        : const [
                            Tab(
                              height: 36,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(PhosphorIconsRegular.squaresFour, size: 15),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text('Posts', maxLines: 1, overflow: TextOverflow.ellipsis),
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
                                  Icon(PhosphorIconsRegular.circlesThree, size: 15),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text('Bubbles', maxLines: 1, overflow: TextOverflow.ellipsis),
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
                                  Icon(PhosphorIconsRegular.userCheck, size: 15),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text('About', maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ),
                          ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: isMe
              ? [
                  // 1. Posts Grid
                  ProfilePostsGrid(
                    posts: _posts,
                    isLoading: _tabsLoading,
                    emptyMessage: 'No posts yet.',
                  ),

                  // 2. Friends Tab
                  ProfileFriendsTab(
                    friends: _friends,
                    isLoading: _tabsLoading,
                    emptyMessage: 'No friends yet.',
                    onFriendTap: (friendId) {
                      if (friendId.isNotEmpty) {
                        context.push('/user/$friendId');
                      }
                    },
                  ),

                  // 3. Bubbles Tab
                  ProfileBubblesTab(
                    bubbles: _bubbles,
                    isLoading: _tabsLoading,
                    emptyMessage: 'Not in any bubbles yet.',
                    onCreateBubble: () async {
                      await context.push('/profile/bubble/create');
                      ref.read(profileControllerProvider.notifier).refresh();
                      _fetchedUserId = null;
                      if (mounted) _fetchSelfTabData(profile.id);
                    },
                  ),
                ]
              : [
                  // 1. Posts Grid
                  ProfilePostsGrid(
                    posts: _posts,
                    isLoading: _tabsLoading,
                    emptyMessage: 'No posts yet.',
                  ),

                  // 2. Bubbles Tab
                  ProfileBubblesTab(
                    bubbles: _bubbles,
                    isLoading: _tabsLoading,
                    emptyMessage: 'Not in any public bubbles.',
                  ),

                  // 3. About Tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About ${profile.displayName}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: LiquidGlassTheme.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        LiquidGlassContainer(
                          borderRadius: BorderRadius.circular(16),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.bio.isNotEmpty ? profile.bio : 'No bio provided.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: LiquidGlassTheme.textSecondary(context),
                                ),
                              ),
                              if (profile.createdAt != null) ...[
                                const SizedBox(height: 12),
                                Divider(color: Colors.grey.withValues(alpha: 0.15)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      PhosphorIconsRegular.calendarBlank,
                                      size: 16,
                                      color: LiquidGlassTheme.textSecondary(context),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                      'Joined ${DateHelpers.formatShortDate(profile.createdAt!)}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: LiquidGlassTheme.textSecondary(context),
                                      ),
                                    ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
        ),
      ),
    );
  }
}

class ProfileSliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  ProfileSliverTabBarDelegate({
    required this.child,
    this.height = 56.0,
  });

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(ProfileSliverTabBarDelegate oldDelegate) => true;
}
