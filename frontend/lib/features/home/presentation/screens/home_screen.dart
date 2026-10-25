import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../controllers/feed_controller.dart';
import '../../data/services/view_tracking_service.dart';
import '../../../../shared/widgets/post_card.dart';
import '../../../../shared/widgets/liquid_glass.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  final ViewTrackingService _viewTracker = ViewTrackingService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewTracker.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _viewTracker.flush();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final feedNotifier = ref.read(feedControllerProvider.notifier);
    final topInset = MediaQuery.paddingOf(context).top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: LiquidGlassAppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'bubble',
          style: TextStyle(
            fontFamily: 'Alan Sans',
            fontWeight: FontWeight.bold,
            fontSize: 30,
            letterSpacing: -0.5,
            color: LiquidGlassTheme.textPrimary(context),
          ),
        ),
      ),
      body: feedState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Could not connect to the server',
                style: TextStyle(
                  color: LiquidGlassTheme.textSecondary(context),
                ),
              ),
              const SizedBox(height: 16),
              LiquidGlassButton(
                onPressed: () => feedNotifier.refresh(),
                label: 'Retry',
                icon: Icon(
                  PhosphorIconsRegular.arrowClockwise,
                  size: 16,
                  color: LiquidGlassTheme.textPrimary(context),
                ),
              ),
            ],
          ),
        ),
        data: (posts) {
          return RefreshIndicator(
            onRefresh: feedNotifier.refresh,
            edgeOffset: topInset,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: topInset)),
                if (posts.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final post = posts[index];
                      return PostCard(
                        key: ValueKey('home_post_${post.id}'),
                        post: post,
                        onVisibilityChanged: (fraction) {
                          _viewTracker.onVisibilityChanged(post.id, fraction);
                        },
                      );
                    }, childCount: posts.length),
                  ),

                // Anti-Doomscroll Finish Line
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 40.0,
                      horizontal: 20.0,
                    ),
                    child: LiquidGlassContainer(
                      padding: const EdgeInsets.all(28),
                      borderRadius: BorderRadius.circular(28),
                      hasBlur: false,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.15),
                              border: Border.all(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.35),
                                width: 1.2,
                              ),
                            ),
                            child: const Icon(
                              PhosphorIconsFill.checkCircle,
                              size: 40,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "You're all caught up!",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                              color: LiquidGlassTheme.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "You've seen all new posts from your followed bubbles.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: LiquidGlassTheme.textSecondary(context),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              LiquidGlassButton(
                                onPressed: () => feedNotifier.refresh(),
                                label: 'Reload Feed',
                                isPrimary: false,
                                height: 40,
                              ),
                              LiquidGlassButton(
                                onPressed: () => context.go('/search'),
                                label: 'Explore More',
                                isPrimary: true,
                                height: 40,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
    );
  }
}
