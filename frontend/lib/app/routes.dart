import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import '../core/storage/secure_storage.dart';

import '../core/transitions/bubble_page_transitions.dart';

// Auth
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/register_email_screen.dart';
import '../features/auth/presentation/screens/register_otp_screen.dart';
import '../features/auth/presentation/screens/register_profile_screen.dart';

// Shell & Tabs
import '../shared/components/main_scaffold.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/search/presentation/screens/search_screen.dart';
import '../features/chat/presentation/screens/chat_inbox_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';

// Sub-Routes (Full Screen)
import '../features/home/presentation/screens/create_post_screen.dart';
import '../features/home/presentation/screens/gallery_screen.dart';
import '../features/home/presentation/screens/post_detail_screen.dart';
import '../features/chat/presentation/screens/active_chat_screen.dart';
import '../features/search/presentation/screens/create_bubble_screen.dart';
import '../features/profile/presentation/screens/settings_screen.dart';
import '../features/profile/presentation/screens/friend_settings_screen.dart';
import '../features/profile/presentation/screens/bubble_notification_settings_screen.dart';
import '../features/profile/presentation/screens/post_notification_settings_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/profile/presentation/screens/sessions_settings_screen.dart';

import '../features/auth/presentation/screens/splash_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  redirect: (context, state) {
    if (state.uri.path == '/splash')
      return null; // Let splash screen handle the initial load

    final sessionToken = SecureStorage.cachedSessionToken;
    final isLoggingIn =
        state.uri.path == '/login' ||
        state.uri.path == '/forgot-password' ||
        state.uri.path.startsWith('/register');

    if (sessionToken == null && !isLoggingIn) {
      return '/login';
    }
    if (sessionToken != null && isLoggingIn) {
      return '/home';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) => BubbleFadeThroughTransitionPage(
        key: state.pageKey,
        child: const SplashScreen(),
      ),
    ),
    // --- 1. AUTH ROUTES (No Nav Bar) ---
    GoRoute(
      path: '/login',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) => BubbleFadeThroughTransitionPage(
        key: state.pageKey,
        child: const LoginScreen(),
      ),
    ),
    GoRoute(
      path: '/forgot-password',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) => BubbleFluidSlideTransitionPage(
        key: state.pageKey,
        child: const ForgotPasswordScreen(),
      ),
    ),
    GoRoute(
      path: '/register/email',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) => BubbleFluidSlideTransitionPage(
        key: state.pageKey,
        child: RegisterEmailScreen(),
      ),
    ),
    GoRoute(
      path: '/register/otp',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) => BubbleFluidSlideTransitionPage(
        key: state.pageKey,
        child: RegisterOtpScreen(),
      ),
    ),
    GoRoute(
      path: '/register/profile',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) => BubbleFluidSlideTransitionPage(
        key: state.pageKey,
        child: const RegisterProfileScreen(),
      ),
    ),

    // --- 1.5 GLOBAL SUB-ROUTES ---
    GoRoute(
      path: '/post/:id',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) => BubbleCardMorphTransitionPage(
        key: state.pageKey,
        child: PostDetailScreen(postId: state.pathParameters['id'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/user/:id',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) => BubbleFluidSlideTransitionPage(
        key: state.pageKey,
        child: ProfileScreen(userId: state.pathParameters['id'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/chat/:id',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) => BubbleFluidSlideTransitionPage(
        key: state.pageKey,
        child: ActiveChatScreen(
          conversationId: state.pathParameters['id'] ?? '',
          targetId: state.uri.queryParameters['targetId'],
        ),
      ),
    ),
    GoRoute(
      path: '/create',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) {
        final images = state.extra is List<XFile>
            ? state.extra as List<XFile>
            : null;
        return BubbleMorphTransitionPage(
          key: state.pageKey,
          child: CreatePostScreen(initialImages: images),
        );
      },
    ),

    // --- 2. STATEFUL SHELL ROUTES (Persistent Bottom Nav Bar with Tab State Retention & Animated Page Transitions) ---
    StatefulShellRoute(
      navigatorContainerBuilder: (context, navigationShell, children) {
        return _AnimatedBranchContainer(
          currentIndex: navigationShell.currentIndex,
          children: children,
        );
      },
      builder: (context, state, navigationShell) {
        return MainScaffold(navigationShell: navigationShell);
      },
      branches: [
        // TAB 0: HOME
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (context, state) => BubbleFadeThroughTransitionPage(
                key: state.pageKey,
                child: const HomeScreen(),
              ),
              routes: [
                GoRoute(
                  path: 'create',
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (context, state) {
                    final images = state.extra is List<XFile>
                        ? state.extra as List<XFile>
                        : null;
                    return BubbleMorphTransitionPage(
                      key: state.pageKey,
                      child: CreatePostScreen(initialImages: images),
                    );
                  },
                ),
              ],
            ),
          ],
        ),

        // TAB 1: SEARCH / EXPLORE
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              pageBuilder: (context, state) => BubbleFadeThroughTransitionPage(
                key: state.pageKey,
                child: const SearchScreen(),
              ),
              routes: [
                GoRoute(
                  path: 'bubble/create',
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (context, state) => BubbleMorphTransitionPage(
                    key: state.pageKey,
                    child: const CreateBubbleScreen(),
                  ),
                ),
              ],
            ),
          ],
        ),

        // TAB 2: GALLERY
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/gallery',
              pageBuilder: (context, state) => BubbleFadeThroughTransitionPage(
                key: state.pageKey,
                child: const GalleryScreen(),
              ),
            ),
          ],
        ),

        // TAB 3: INBOX (Activity + DMs)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/inbox',
              pageBuilder: (context, state) => BubbleFadeThroughTransitionPage(
                key: state.pageKey,
                child: const ChatInboxScreen(),
              ),
              routes: [
                GoRoute(
                  path: 'chat/:id',
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (context, state) {
                    return BubbleFluidSlideTransitionPage(
                      key: state.pageKey,
                      child: ActiveChatScreen(
                        conversationId: state.pathParameters['id']!,
                        targetId: state.uri.queryParameters['targetId'],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),

        // TAB 4: PROFILE
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) => BubbleFadeThroughTransitionPage(
                key: state.pageKey,
                child: const ProfileScreen(),
              ),
              routes: [
                GoRoute(
                  path: 'bubble/create',
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (context, state) => BubbleMorphTransitionPage(
                    key: state.pageKey,
                    child: const CreateBubbleScreen(),
                  ),
                ),
                GoRoute(
                  path: 'settings',
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (context, state) =>
                      BubbleFluidSlideTransitionPage(
                        key: state.pageKey,
                        child: const SettingsScreen(),
                      ),
                  routes: [
                    GoRoute(
                      path: 'personalization',
                      parentNavigatorKey: rootNavigatorKey,
                      pageBuilder: (context, state) =>
                          BubbleFluidSlideTransitionPage(
                            key: state.pageKey,
                            child: const FeedSettingsScreen(),
                          ),
                    ),
                    GoRoute(
                      path: 'feed',
                      parentNavigatorKey: rootNavigatorKey,
                      pageBuilder: (context, state) =>
                          BubbleFluidSlideTransitionPage(
                            key: state.pageKey,
                            child: const FeedSettingsScreen(),
                          ),
                    ),
                    GoRoute(
                      path: 'appearance',
                      parentNavigatorKey: rootNavigatorKey,
                      pageBuilder: (context, state) =>
                          BubbleFluidSlideTransitionPage(
                            key: state.pageKey,
                            child: const FeedSettingsScreen(),
                          ),
                    ),
                    GoRoute(
                      path: 'notifications',
                      parentNavigatorKey: rootNavigatorKey,
                      pageBuilder: (context, state) =>
                          BubbleFluidSlideTransitionPage(
                            key: state.pageKey,
                            child: const NotificationSettingsScreen(),
                          ),
                    ),
                    GoRoute(
                      path: 'bubble-notifications',
                      parentNavigatorKey: rootNavigatorKey,
                      pageBuilder: (context, state) =>
                          BubbleFluidSlideTransitionPage(
                            key: state.pageKey,
                            child: const BubbleNotificationSettingsScreen(),
                          ),
                    ),
                    GoRoute(
                      path: 'post-notifications',
                      parentNavigatorKey: rootNavigatorKey,
                      pageBuilder: (context, state) =>
                          BubbleFluidSlideTransitionPage(
                            key: state.pageKey,
                            child: const PostNotificationSettingsScreen(),
                          ),
                    ),
                    GoRoute(
                      path: 'privacy',
                      parentNavigatorKey: rootNavigatorKey,
                      pageBuilder: (context, state) =>
                          BubbleFluidSlideTransitionPage(
                            key: state.pageKey,
                            child: const PrivacySettingsScreen(),
                          ),
                    ),
                    GoRoute(
                      path: 'friends',
                      parentNavigatorKey: rootNavigatorKey,
                      pageBuilder: (context, state) =>
                          BubbleFluidSlideTransitionPage(
                            key: state.pageKey,
                            child: const FriendSettingsListScreen(),
                          ),
                      routes: [
                        GoRoute(
                          path: ':friendId',
                          parentNavigatorKey: rootNavigatorKey,
                          pageBuilder: (context, state) =>
                              BubbleFluidSlideTransitionPage(
                                key: state.pageKey,
                                child: FriendSettingsScreen(
                                  friendId: state.pathParameters['friendId']!,
                                ),
                              ),
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'blocked',
                      parentNavigatorKey: rootNavigatorKey,
                      pageBuilder: (context, state) =>
                          BubbleFluidSlideTransitionPage(
                            key: state.pageKey,
                            child: const BlockedAccountsScreen(),
                          ),
                    ),
                    GoRoute(
                      path: 'account',
                      parentNavigatorKey: rootNavigatorKey,
                      pageBuilder: (context, state) =>
                          BubbleFluidSlideTransitionPage(
                            key: state.pageKey,
                            child: const AccountSettingsScreen(),
                          ),
                      routes: [
                        GoRoute(
                          path: 'sessions',
                          parentNavigatorKey: rootNavigatorKey,
                          pageBuilder: (context, state) =>
                              BubbleFluidSlideTransitionPage(
                                key: state.pageKey,
                                child: const SessionsSettingsScreen(),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
                GoRoute(
                  path: 'edit',
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (context, state) => BubbleMorphTransitionPage(
                    key: state.pageKey,
                    child: const EditProfileScreen(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

/// Animated container that preserves state of all tab branches while providing smooth
/// directional slide, scale, and cross-fade transitions relative to the navigation bar layout.
class _AnimatedBranchContainer extends StatefulWidget {
  final int currentIndex;
  final List<Widget> children;

  const _AnimatedBranchContainer({
    required this.currentIndex,
    required this.children,
  });

  @override
  State<_AnimatedBranchContainer> createState() =>
      _AnimatedBranchContainerState();
}

class _AnimatedBranchContainerState extends State<_AnimatedBranchContainer>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  int? _previousIndex;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: BubbleTransitionDurations.tabSwitch,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant _AnimatedBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _currentIndex = widget.currentIndex;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final progress = _animation.value;
        final isAnimating =
            _controller.isAnimating &&
            _previousIndex != null &&
            _previousIndex != _currentIndex;

        final stackChildren = <Widget>[];

        // 1. Offstage all non-participating branches to preserve state without rendering overhead
        for (int i = 0; i < widget.children.length; i++) {
          if (i != _currentIndex && (!isAnimating || i != _previousIndex)) {
            stackChildren.add(
              Offstage(
                key: ValueKey('tab_offstage_$i'),
                offstage: true,
                child: TickerMode(enabled: false, child: widget.children[i]),
              ),
            );
          }
        }

        // 2. If animating, render previous (exiting) branch in the background layer
        if (isAnimating) {
          final direction = _currentIndex > _previousIndex! ? 1.0 : -1.0;
          final dx = -progress * 0.07 * direction;
          final opacity = (1.0 - progress).clamp(0.0, 1.0);
          final scale = 1.0 - (0.018 * progress);

          stackChildren.add(
            IgnorePointer(
              key: ValueKey('tab_exiting_$_previousIndex'),
              ignoring: true,
              child: FractionalTranslation(
                translation: Offset(dx, 0.0),
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: opacity,
                    child: TickerMode(
                      enabled: false,
                      child: widget.children[_previousIndex!],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        // 3. Render current (entering) branch on TOP with fluid directional glide and scale
        final double currentDx;
        final double currentOpacity;
        final double currentScale;

        if (isAnimating) {
          final direction = _currentIndex > _previousIndex! ? 1.0 : -1.0;
          currentDx = (1.0 - progress) * 0.10 * direction;
          currentOpacity = progress.clamp(0.0, 1.0);
          currentScale = 0.985 + (0.015 * progress);
        } else {
          currentDx = 0.0;
          currentOpacity = 1.0;
          currentScale = 1.0;
        }

        stackChildren.add(
          FractionalTranslation(
            key: ValueKey('tab_current_$_currentIndex'),
            translation: Offset(currentDx, 0.0),
            child: Transform.scale(
              scale: currentScale,
              alignment: Alignment.center,
              child: Opacity(
                opacity: currentOpacity,
                child: TickerMode(
                  enabled: true,
                  child: widget.children[_currentIndex],
                ),
              ),
            ),
          ),
        );

        return Stack(fit: StackFit.expand, children: stackChildren);
      },
    );
  }
}
