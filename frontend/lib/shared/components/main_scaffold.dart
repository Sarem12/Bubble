import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/dynamic_dock_provider.dart';
import '../widgets/dynamic_dock.dart';

class MainScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({
    super.key,
    required this.navigationShell,
  });

  void _onItemTapped(WidgetRef ref, int index) {
    // Reset any active selection/comment/newChat/emoji/reaction mode when navigating to a new tab
    final dock = ref.read(dynamicDockProvider);
    if (dock.mode != DynamicDockMode.navigation) {
      dock.onSelectionCancel?.call();
      dock.onCommentClose?.call();
      dock.onNewChatClose?.call();
      dock.onEmojiClose?.call();
      dock.onReactionClose?.call();
      ref.read(dynamicDockProvider.notifier).resetToNavigation();
    }

    if (index != navigationShell.currentIndex) {
      ref.read(dynamicDockProvider.notifier).setScrolled(false);
    }

    navigationShell.goBranch(
      index,
      // If tapping the currently selected branch, reset branch to its initial location
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dockState = ref.watch(dynamicDockProvider);
    final isExpandedActive = dockState.mode == DynamicDockMode.comments ||
        dockState.mode == DynamicDockMode.newChat ||
        dockState.mode == DynamicDockMode.emojiPicker ||
        dockState.mode == DynamicDockMode.share ||
        dockState.mode == DynamicDockMode.reactionBar;
    final isModalDockActive = isExpandedActive ||
        dockState.mode == DynamicDockMode.selection ||
        dockState.mode == DynamicDockMode.quickComment;

    return PopScope(
      canPop: !isModalDockActive && navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // If in modal dock mode, first dismiss the dynamic dock
        if (isModalDockActive) {
          dockState.onSelectionCancel?.call();
          dockState.onCommentClose?.call();
          dockState.onNewChatClose?.call();
          dockState.onEmojiClose?.call();
          dockState.onShareClose?.call();
          dockState.onReactionClose?.call();
          ref.read(dynamicDockProvider.notifier).resetToNavigation();
          return;
        }

        // Check if root navigator or active branch can pop
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
          return;
        }

        // Otherwise go to home tab
        if (navigationShell.currentIndex != 0) {
          navigationShell.goBranch(0);
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBody: true,
        body: Stack(
          children: [
            Positioned.fill(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification.metrics.axis == Axis.vertical) {
                    final isScrolled = notification.metrics.pixels > 15.0;
                    ref.read(dynamicDockProvider.notifier).setScrolled(isScrolled);
                  }
                  return false;
                },
                child: navigationShell,
              ),
            ),
            // Non-shading tap catcher to dismiss morphed dock when tapping outside without dimming/shading background
            if (isExpandedActive)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    if (dockState.mode == DynamicDockMode.comments) {
                      dockState.onCommentClose?.call();
                    } else if (dockState.mode == DynamicDockMode.newChat) {
                      dockState.onNewChatClose?.call();
                    } else if (dockState.mode == DynamicDockMode.emojiPicker) {
                      dockState.onEmojiClose?.call();
                    } else if (dockState.mode == DynamicDockMode.share) {
                      dockState.onShareClose?.call();
                    } else if (dockState.mode == DynamicDockMode.reactionBar) {
                      dockState.onReactionClose?.call();
                    }
                    ref.read(dynamicDockProvider.notifier).resetToNavigation();
                  },
                ),
              ),
            // Morphing Dynamic Liquid Dock aligned at bottom
            Align(
              alignment: Alignment.bottomCenter,
              child: DynamicDock(
                selectedIndex: navigationShell.currentIndex,
                onItemTapped: (index) => _onItemTapped(ref, index),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
