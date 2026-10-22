import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/safe_haptics.dart';

/// Fluid easing curves matching the Liquid Glass physics.
class BubbleCurves {
  /// Primary cubic ease-out for entering elements (decelerates smoothly)
  static const Curve easeOut = Curves.easeOutCubic;

  /// Smooth ease-in for exiting elements
  static const Curve easeIn = Curves.easeInCubic;

  /// Silky reverse curve for responsive pop transitions
  static const Curve easeOutReverse = Curves.easeOutCubic;

  /// Emphasized fluid curve for sheet/card morphing
  static const Curve morphCurve = Cubic(0.2, 0.9, 0.3, 1.0);
}

/// Standard durations for consistent fluid animations across the Bubble app.
class BubbleTransitionDurations {
  /// Navigation bar tab switch duration (synchronized with the dock pill)
  static const Duration tabSwitch = Duration(milliseconds: 280);

  /// Fluid modal morph duration (create studio, sheets)
  static const Duration morphModal = Duration(milliseconds: 340);

  /// Card to full-screen morph duration (post detail)
  static const Duration cardMorph = Duration(milliseconds: 320);

  /// Lateral fluid push duration (chat, profile, settings)
  static const Duration fluidPush = Duration(milliseconds: 300);

  /// Fade-through duration (auth, splash)
  static const Duration fadeThrough = Duration(milliseconds: 260);

  /// Reverse duration for faster pop responsiveness
  static const Duration reverseDefault = Duration(milliseconds: 240);
}

/// Interactive Edge-Swipe gesture detector for lateral pushed pages.
/// Detects a horizontal drag originating within 28px of the left screen edge
/// and triggers a smooth pop navigation with tactile haptic feedback.
class BubbleEdgeSwipeBackDetector extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const BubbleEdgeSwipeBackDetector({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<BubbleEdgeSwipeBackDetector> createState() => _BubbleEdgeSwipeBackDetectorState();
}

class _BubbleEdgeSwipeBackDetectorState extends State<BubbleEdgeSwipeBackDetector> {
  double _dragStartX = 0.0;
  bool _isEligible = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          width: 28,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (details) {
              _dragStartX = details.globalPosition.dx;
              _isEligible = _dragStartX <= 32.0;
            },
            onHorizontalDragUpdate: (details) {
              if (!_isEligible) return;
              final delta = details.globalPosition.dx - _dragStartX;
              if (delta > 48) {
                _isEligible = false;
                SafeHaptics.lightImpact();
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else if (context.canPop()) {
                  context.pop();
                }
              }
            },
            onHorizontalDragEnd: (_) {
              _isEligible = false;
            },
            onHorizontalDragCancel: () {
              _isEligible = false;
            },
          ),
        ),
      ],
    );
  }
}

/// 1. Modal Morph Transition Page
/// Used for studio & creation pages (/create, /home/create, /search/bubble/create, /profile/edit).
/// Morphs fluidly upwards from the dock with scale expansion, corner radius morph,
/// and smooth dark glass backdrop scrim. Also supports secondary depth stacking
/// when sub-tools (camera, editor) push on top.
class BubbleMorphTransitionPage<T> extends CustomTransitionPage<T> {
  BubbleMorphTransitionPage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  }) : super(
          transitionDuration: BubbleTransitionDurations.morphModal,
          reverseTransitionDuration: BubbleTransitionDurations.reverseDefault,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: BubbleCurves.morphCurve,
              reverseCurve: BubbleCurves.easeOutReverse,
            );

            // Upward fluid translation from dock
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0.0, 0.12),
              end: Offset.zero,
            ).animate(curved);

            // Subtle scale expansion
            final scaleAnimation = Tween<double>(
              begin: 0.93,
              end: 1.0,
            ).animate(curved);

            // Morph corner radius from rounded dock pill to edge-to-edge
            final radiusAnimation = Tween<double>(
              begin: 32.0,
              end: 0.0,
            ).animate(curved);

            // Fast fade-in
            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
            ));

            // Secondary animation for when another screen pushes on top (stacked modal feel)
            final secCurved = CurvedAnimation(
              parent: secondaryAnimation,
              curve: BubbleCurves.easeOut,
              reverseCurve: BubbleCurves.easeOutReverse,
            );
            final secScale = Tween<double>(begin: 1.0, end: 0.95).animate(secCurved);
            final secSlide = Tween<Offset>(begin: Offset.zero, end: const Offset(0.0, 0.02)).animate(secCurved);
            final secDim = Tween<double>(begin: 0.0, end: 0.25).animate(secCurved);
            final secRadius = Tween<double>(begin: 0.0, end: 16.0).animate(secCurved);

            return Stack(
              fit: StackFit.expand,
              children: [
                // Dark glass scrim backdrop
                AnimatedBuilder(
                  animation: animation,
                  builder: (context, _) => Container(
                    color: Colors.black.withValues(
                      alpha: 0.40 * animation.value.clamp(0.0, 1.0),
                    ),
                  ),
                ),
                // Morphed child with secondary depth stacking
                SlideTransition(
                  position: secSlide,
                  child: ScaleTransition(
                    scale: secScale,
                    alignment: Alignment.topCenter,
                    child: AnimatedBuilder(
                      animation: secondaryAnimation,
                      builder: (context, currentChild) {
                        final r = secRadius.value;
                        Widget w = currentChild!;
                        if (r > 0.5) {
                          w = ClipRRect(
                            borderRadius: BorderRadius.circular(r),
                            child: w,
                          );
                        }
                        if (secDim.value > 0.001) {
                          w = Stack(
                            fit: StackFit.expand,
                            children: [
                              w,
                              Container(
                                color: Colors.black.withValues(alpha: secDim.value),
                              ),
                            ],
                          );
                        }
                        return w;
                      },
                      child: SlideTransition(
                        position: slideAnimation,
                        child: ScaleTransition(
                          scale: scaleAnimation,
                          alignment: Alignment.bottomCenter,
                          child: FadeTransition(
                            opacity: fadeAnimation,
                            child: AnimatedBuilder(
                              animation: radiusAnimation,
                              builder: (context, innerChild) {
                                final r = radiusAnimation.value;
                                if (r <= 0.5) return innerChild!;
                                return ClipRRect(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(r),
                                  ),
                                  child: innerChild,
                                );
                              },
                              child: child,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
}

/// 2. Card Morph Transition Page
/// Used for /post/:id (Post Detail Screen).
/// Morphs fluidly from the tapped card into full-screen with scale (0.92 -> 1.0),
/// vertical lift, and curved opacity fade, while underlying screen recedes with depth.
class BubbleCardMorphTransitionPage<T> extends CustomTransitionPage<T> {
  BubbleCardMorphTransitionPage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  }) : super(
          transitionDuration: BubbleTransitionDurations.cardMorph,
          reverseTransitionDuration: BubbleTransitionDurations.reverseDefault,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: BubbleCurves.morphCurve,
              reverseCurve: BubbleCurves.easeOutReverse,
            );

            // Forward scale expansion
            final scaleAnimation = Tween<double>(
              begin: 0.92,
              end: 1.0,
            ).animate(curved);

            // Vertical lift
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0.0, 0.05),
              end: Offset.zero,
            ).animate(curved);

            // Fluid fade
            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
            ));

            // Secondary animation for when another page pushes on top
            final secCurved = CurvedAnimation(
              parent: secondaryAnimation,
              curve: BubbleCurves.easeOut,
              reverseCurve: BubbleCurves.easeOutReverse,
            );
            final secScaleAnimation = Tween<double>(
              begin: 1.0,
              end: 0.96,
            ).animate(secCurved);

            final secDimAnimation = Tween<double>(
              begin: 0.0,
              end: 0.20,
            ).animate(secCurved);

            return ScaleTransition(
              scale: secScaleAnimation,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  SlideTransition(
                    position: slideAnimation,
                    child: ScaleTransition(
                      scale: scaleAnimation,
                      alignment: Alignment.center,
                      child: FadeTransition(
                        opacity: fadeAnimation,
                        child: BubbleEdgeSwipeBackDetector(child: child),
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: secondaryAnimation,
                    builder: (context, _) {
                      final val = secDimAnimation.value;
                      if (val <= 0.001) return const SizedBox.shrink();
                      return Container(
                        color: Colors.black.withValues(alpha: val),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
}

/// 3. Fluid Slide & Parallax Transition Page
/// Used for lateral navigation: /chat/:id, /user/:id, /profile/settings, /register/*, etc.
/// Slides in from right (1.0 -> 0.0) with edge glass shadow, while
/// the previous screen retreats with parallax (-0.20 -> 0.0), subtle depth scale (0.965),
/// and a dark depth veil. Includes interactive edge-swipe back support.
class BubbleFluidSlideTransitionPage<T> extends CustomTransitionPage<T> {
  BubbleFluidSlideTransitionPage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  }) : super(
          transitionDuration: BubbleTransitionDurations.fluidPush,
          reverseTransitionDuration: BubbleTransitionDurations.reverseDefault,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: BubbleCurves.easeOut,
              reverseCurve: BubbleCurves.easeOutReverse,
            );

            // Primary slide from right
            final primarySlide = Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(curved);

            // Secondary retreat for underlying screen when another pushes over it
            final secCurved = CurvedAnimation(
              parent: secondaryAnimation,
              curve: BubbleCurves.easeOut,
              reverseCurve: BubbleCurves.easeOutReverse,
            );
            final secSlide = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.20, 0.0),
            ).animate(secCurved);

            final secScale = Tween<double>(
              begin: 1.0,
              end: 0.965,
            ).animate(secCurved);

            final secDim = Tween<double>(
              begin: 0.0,
              end: 0.22,
            ).animate(secCurved);

            final isDark = Theme.of(context).brightness == Brightness.dark;

            return SlideTransition(
              position: secSlide,
              child: ScaleTransition(
                scale: secScale,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SlideTransition(
                      position: primarySlide,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.38 : 0.16,
                              ),
                              blurRadius: 30,
                              offset: const Offset(-8, 0),
                            ),
                          ],
                        ),
                        child: BubbleEdgeSwipeBackDetector(child: child),
                      ),
                    ),
                    // Parallax depth veil for the screen when it is pushed under another
                    AnimatedBuilder(
                      animation: secondaryAnimation,
                      builder: (context, _) {
                        final val = secDim.value;
                        if (val <= 0.001) return const SizedBox.shrink();
                        return Container(
                          color: Colors.black.withValues(alpha: val),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
}

/// 4. Fade-Through Transition Page
/// Used for /login, /splash, and top-level root tabs.
/// Subtle scale (0.96 -> 1.0) with clean fade-through.
class BubbleFadeThroughTransitionPage<T> extends CustomTransitionPage<T> {
  BubbleFadeThroughTransitionPage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  }) : super(
          transitionDuration: BubbleTransitionDurations.fadeThrough,
          reverseTransitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: BubbleCurves.easeOut,
              reverseCurve: BubbleCurves.easeIn,
            );

            final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
            final scale = Tween<double>(begin: 0.96, end: 1.0).animate(curved);
            // Fade and recede the page underneath while the new page enters.
            final secondaryCurved = CurvedAnimation(
              parent: secondaryAnimation,
              curve: BubbleCurves.easeOut,
              reverseCurve: BubbleCurves.easeIn,
            );
            final secondaryFade = Tween<double>(begin: 1.0, end: 0.0).animate(
              CurvedAnimation(
                parent: secondaryCurved,
                curve: const Interval(0.0, 0.7),
              ),
            );
            final secondaryScale = Tween<double>(begin: 1.0, end: 0.98)
                .animate(secondaryCurved);

            return FadeTransition(
              opacity: secondaryFade,
              child: ScaleTransition(
                scale: secondaryScale,
                child: FadeTransition(
                  opacity: fade,
                  child: ScaleTransition(scale: scale, child: child),
                ),
              ),
            );
          },
        );
}

/// 5. Imperative Modal Route Builder (for Navigator.push)
/// Provides the same upward fluid morph for CameraScreen, PhotoEditorScreen, etc.
class BubbleMorphModalRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  BubbleMorphModalRoute({required this.page, super.settings})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: BubbleTransitionDurations.morphModal,
          reverseTransitionDuration: BubbleTransitionDurations.reverseDefault,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: BubbleCurves.morphCurve,
              reverseCurve: BubbleCurves.easeOutReverse,
            );

            final slideAnimation = Tween<Offset>(
              begin: const Offset(0.0, 0.12),
              end: Offset.zero,
            ).animate(curved);

            final scaleAnimation = Tween<double>(
              begin: 0.93,
              end: 1.0,
            ).animate(curved);

            final radiusAnimation = Tween<double>(
              begin: 28.0,
              end: 0.0,
            ).animate(curved);

            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
            ));

            return Stack(
              fit: StackFit.expand,
              children: [
                AnimatedBuilder(
                  animation: animation,
                  builder: (context, _) => Container(
                    color: Colors.black.withValues(
                      alpha: 0.40 * animation.value.clamp(0.0, 1.0),
                    ),
                  ),
                ),
                SlideTransition(
                  position: slideAnimation,
                  child: ScaleTransition(
                    scale: scaleAnimation,
                    alignment: Alignment.bottomCenter,
                    child: FadeTransition(
                      opacity: fadeAnimation,
                      child: AnimatedBuilder(
                        animation: radiusAnimation,
                        builder: (context, innerChild) {
                          final r = radiusAnimation.value;
                          if (r <= 0.5) return innerChild!;
                          return ClipRRect(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(r),
                            ),
                            child: innerChild,
                          );
                        },
                        child: child,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
}

/// 6. Photo Morph Route (for PhotoDetailViewerScreen)
/// Pure backdrop fade that lets Hero image zoom seamlessly from thumbnail to full screen
/// without competing scale distortion.
class BubblePhotoMorphRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  BubblePhotoMorphRoute({required this.page, super.settings})
      : super(
          opaque: false,
          barrierColor: Colors.transparent,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeOutCubic,
            );

            final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curved);

            return FadeTransition(
              opacity: fade,
              child: child,
            );
          },
        );
}
