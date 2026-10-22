import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import '../../features/profile/presentation/controllers/profile_controller.dart';
import '../../features/profile/presentation/controllers/settings_controller.dart';
import '../../features/profile/data/datasources/friend_remote_datasource.dart';
import '../emoji/app_emoji.dart';
import '../emoji/bubble_emoji.dart';
import '../emoji/bubble_emoji_picker.dart';
import '../providers/dynamic_dock_provider.dart';
import 'comment_bottom_sheet.dart';
import 'new_chat_dock_panel.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../core/utils/ui_helpers.dart';
import '../../core/transitions/bubble_page_transitions.dart';
import 'liquid_glass.dart';
import 'user_avatar.dart';
import 'smart_user_avatar.dart';

/// Dynamic dock that fluidly transforms between:
/// 1. Standard 5-tab navigation bar
/// 2. Full Morphing Comments panel (morphing upwards with comments list & replies)
/// 3. Contextual multi-selection action bar
/// 4. Quick comment / reply input dock
/// 5. Full Morphing Emoji Picker panel
/// 6. Animated Reaction Bar dock
/// 7. Custom toolbars and spring pop-out action tools
class DynamicDock extends ConsumerStatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const DynamicDock({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  ConsumerState<DynamicDock> createState() => _DynamicDockState();
}

class _DynamicDockState extends ConsumerState<DynamicDock>
    with SingleTickerProviderStateMixin {
  late TextEditingController _commentTextController;
  late FocusNode _commentFocusNode;
  bool _hasCommentText = false;
  late AnimationController _morphPulseController;
  late Animation<double> _morphScaleAnimation;
  DynamicDockMode? _lastMode;
  int _lastSelectionCount = 0;
  static const int _selectedNavFlex = 19;
  static const int _unselectedNavFlex = 10;

  @override
  void initState() {
    super.initState();
    _commentTextController = TextEditingController();
    _commentFocusNode = FocusNode();

    _morphPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _morphScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.96,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.96,
          end: 1.025,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.025,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 30,
      ),
    ]).animate(_morphPulseController);

    _commentTextController.addListener(() {
      final hasText = _commentTextController.text.trim().isNotEmpty;
      if (hasText != _hasCommentText) {
        setState(() {
          _hasCommentText = hasText;
        });
      }
    });
  }

  @override
  void dispose() {
    _morphPulseController.dispose();
    _commentTextController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dockState = ref.watch(dynamicDockProvider);
    final isPhotoViewerMode = dockState.mode == DynamicDockMode.photoViewer;
    final isDark =
        Theme.of(context).brightness == Brightness.dark || isPhotoViewerMode;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    final isCommentsMode = dockState.mode == DynamicDockMode.comments;
    final isNewChatMode = dockState.mode == DynamicDockMode.newChat;
    final isEmojiPickerMode = dockState.mode == DynamicDockMode.emojiPicker;
    final isReactionBarMode = dockState.mode == DynamicDockMode.reactionBar;
    final isShareMode = dockState.mode == DynamicDockMode.share;
    final isExpandedMode =
        isCommentsMode || isNewChatMode || isEmojiPickerMode || isShareMode;
    final isQuickCommentMode = dockState.mode == DynamicDockMode.quickComment;

    final bool shouldHide =
        !dockState.isVisible ||
        (!isExpandedMode && !isQuickCommentMode && keyboardInset > 0);

    // Sync initial comment text if set
    if (isQuickCommentMode &&
        dockState.initialCommentText != null &&
        _commentTextController.text != dockState.initialCommentText) {
      _commentTextController.text = dockState.initialCommentText!;
      _commentTextController.selection = TextSelection.fromPosition(
        TextPosition(offset: _commentTextController.text.length),
      );
    }

    // Trigger morph pulse on mode or selection count changes
    if (_lastMode != null &&
        (_lastMode != dockState.mode ||
            (_lastMode == DynamicDockMode.selection &&
                _lastSelectionCount != dockState.selectionCount))) {
      _morphPulseController.forward(from: 0.0);
    }
    _lastMode = dockState.mode;
    _lastSelectionCount = dockState.selectionCount;

    // Dynamic morphing height - comments & newChat to 72% screen height, share popout to 240, emojiPicker to 390
    final double barHeight = (isCommentsMode || isNewChatMode)
        ? (screenHeight * 0.72)
        : (isShareMode
              ? 240.0
              : (isEmojiPickerMode
                    ? 390.0
                    : (isReactionBarMode
                          ? 68.0
                          : (isQuickCommentMode ? 64.0 : 60.0))));

    // Uniform corner radius across all dock states
    const double radiusValue = 30.0;
    final BorderRadius barRadius = BorderRadius.circular(radiusValue);

    // Uniform floating dock padding (16 left/right, consistent bottom line position)
    final double bottomMargin = keyboardInset > 0
        ? keyboardInset + 8
        : (bottomPadding > 0 ? bottomPadding : 16.0);
    final EdgeInsets dockPadding = EdgeInsets.fromLTRB(16, 0, 16, bottomMargin);

    return AnimatedSlide(
      offset: shouldHide ? const Offset(0, 1.5) : Offset.zero,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      child: IgnorePointer(
        ignoring: shouldHide,
        child: RepaintBoundary(
          child: SafeArea(
            top: false,
            bottom: false,
            child: Padding(
              padding: dockPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Spring Pop-Out Tools Row (Pops up above dock when triggered)
                  if (!isExpandedMode) _buildPopoutRow(dockState, isDark),

                  // 2. Main Dynamic Morphing Glass Pill / Container
                  ScaleTransition(
                    scale: _morphScaleAnimation,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      height: barHeight,
                      decoration: BoxDecoration(
                        borderRadius: barRadius,
                        boxShadow: LiquidGlassTheme.dockSurfaceShadows(
                          isDark: isDark,
                          isScrolled: dockState.isScrolled,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: barRadius,
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: dockState.isScrolled ? 26 : 22,
                            sigmaY: dockState.isScrolled ? 26 : 22,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            height: barHeight,
                            decoration: BoxDecoration(
                              gradient: LiquidGlassTheme.dockSurfaceGradient(
                                isDark: isDark,
                                emphasized: isExpandedMode,
                              ),
                              borderRadius: barRadius,
                              border: Border.all(
                                color: LiquidGlassTheme.dockSurfaceBorder(
                                  isDark: isDark,
                                ),
                                width: 1.1,
                              ),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                IgnorePointer(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient:
                                          LiquidGlassTheme.dockSurfaceSheen(
                                            isDark: isDark,
                                          ),
                                    ),
                                  ),
                                ),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  layoutBuilder:
                                      (currentChild, previousChildren) {
                                        return Stack(
                                          fit: StackFit.expand,
                                          alignment: Alignment.bottomCenter,
                                          children: <Widget>[
                                            ...previousChildren,
                                            ?currentChild,
                                          ],
                                        );
                                      },
                                  transitionBuilder: (child, animation) {
                                    final curved = CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutCubic,
                                      reverseCurve: Curves.easeInCubic,
                                    );
                                    return FadeTransition(
                                      opacity: curved,
                                      child: SlideTransition(
                                        position:
                                            Tween<Offset>(
                                              begin: const Offset(0, 0.20),
                                              end: Offset.zero,
                                            ).animate(
                                              CurvedAnimation(
                                                parent: animation,
                                                curve: Curves.easeOutBack,
                                              ),
                                            ),
                                        child: ScaleTransition(
                                          scale: Tween<double>(
                                            begin: 0.94,
                                            end: 1.0,
                                          ).animate(curved),
                                          child: child,
                                        ),
                                      ),
                                    );
                                  },
                                  child: _buildDockContent(
                                    dockState,
                                    isDark,
                                    30.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Spring Pop-Out Actions (Floating tools row above the dock)
  Widget _buildPopoutRow(DynamicDockState dockState, bool isDark) {
    final isOpen = dockState.isPopoutOpen && dockState.popoutItems.isNotEmpty;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.4),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1.0).animate(animation),
              child: child,
            ),
          ),
        );
      },
      child: isOpen
          ? Padding(
              key: const ValueKey('popout_open'),
              padding: const EdgeInsets.only(bottom: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LiquidGlassTheme.dockSurfaceGradient(
                        isDark: isDark,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: LiquidGlassTheme.dockSurfaceBorder(
                          isDark: isDark,
                        ),
                        width: 1.1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.38 : 0.12,
                          ),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LiquidGlassTheme.dockSurfaceSheen(
                                  isDark: isDark,
                                ),
                              ),
                            ),
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: dockState.popoutItems.map((item) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: InkWell(
                                  onTap: () {
                                    SafeHaptics.lightImpact();
                                    item.onTap();
                                    ref
                                        .read(dynamicDockProvider.notifier)
                                        .closePopout();
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          item.backgroundColor ??
                                          (isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.08,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.05,
                                                )),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          item.icon,
                                          size: 16,
                                          color:
                                              item.iconColor ??
                                              (isDark
                                                  ? Colors.white
                                                  : Colors.black87),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          item.label,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(key: ValueKey('popout_closed')),
    );
  }

  /// Morphing content router
  Widget _buildDockContent(
    DynamicDockState dockState,
    bool isDark,
    double barRadius,
  ) {
    switch (dockState.mode) {
      case DynamicDockMode.comments:
        return _buildMorphingCommentsDock(dockState);

      case DynamicDockMode.newChat:
        return _buildMorphingNewChatDock(dockState);

      case DynamicDockMode.share:
        return _buildMorphingShareDock(dockState);

      case DynamicDockMode.emojiPicker:
        return _buildMorphingEmojiDock(dockState, isDark);

      case DynamicDockMode.reactionBar:
        return _buildMorphingReactionBar(dockState, isDark);

      case DynamicDockMode.selection:
        return _buildSelectionDock(dockState, isDark);

      case DynamicDockMode.quickComment:
        return _buildQuickCommentDock(dockState, isDark);

      case DynamicDockMode.photoViewer:
        return _buildPhotoViewerDock(dockState, isDark);

      case DynamicDockMode.custom:
        return KeyedSubtree(
          key: const ValueKey('custom_dock'),
          child: dockState.customWidget ?? const SizedBox.shrink(),
        );

      case DynamicDockMode.navigation:
        return _buildNavigationDock(isDark, barRadius, dockState.isScrolled);
    }
  }

  // ==========================================
  // 1.8. FULL MORPHING EMOJI PICKER DOCK
  // ==========================================
  Widget _buildMorphingEmojiDock(DynamicDockState dockState, bool isDark) {
    final title = dockState.emojiTitle ?? 'Select Emoji';

    return SizedBox.expand(
      key: const ValueKey('emoji_picker_dock'),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 250) {
            SafeHaptics.lightImpact();
            dockState.onEmojiClose?.call();
            ref.read(dynamicDockProvider.notifier).resetToNavigation();
          }
        },
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topCenter,
            minHeight: 0,
            maxHeight: 390.0,
            child: SizedBox(
              height: 390.0,
              child: Column(
                children: [
                  // 1. Top Drag Handle (matching Comments & New Chat)
                  const SizedBox(height: 10),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // 2. Header Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          PhosphorIconsRegular.smiley,
                          size: 20,
                          color: LiquidGlassTheme.textPrimary(context),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              letterSpacing: -0.2,
                              color: LiquidGlassTheme.textPrimary(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            SafeHaptics.lightImpact();
                            dockState.onEmojiClose?.call();
                            ref
                                .read(dynamicDockProvider.notifier)
                                .resetToNavigation();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.black.withValues(alpha: 0.05),
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
                  Divider(
                    height: 1,
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                  ),

                  // 3. Embedded Animated Emoji Picker filling the expanded morph sheet
                  Expanded(
                    child: BubbleEmojiPicker(
                      showSearchBar: true,
                      showPreview: true,
                      initialCategory: dockState.emojiInitialCategory,
                      onEmojiSelected: (emoji) {
                        SafeHaptics.mediumImpact();
                        ref
                            .read(dynamicDockProvider.notifier)
                            .completeEmojiSelection(emoji);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 1.9. MORPHING REACTION BAR DOCK
  // ==========================================
  Widget _buildMorphingReactionBar(DynamicDockState dockState, bool isDark) {
    final configuredReactions = ref
        .watch(settingsControllerProvider)
        .value
        ?.topReactions;
    final topReactionEmojis =
        configuredReactions == null || configuredReactions.isEmpty
        ? const ['❤️', '😂', '🔥', '👍', '😮']
        : configuredReactions;

    final activeEmoji = dockState.reactionActiveEmoji;

    return Container(
      key: const ValueKey('reaction_bar_dock'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Close button
          GestureDetector(
            onTap: () {
              SafeHaptics.lightImpact();
              dockState.onReactionClose?.call();
              ref.read(dynamicDockProvider.notifier).resetToNavigation();
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.x,
                size: 18,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Reaction Emojis
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: topReactionEmojis.map((emoji) {
                  final isActive = activeEmoji == emoji;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () {
                        SafeHaptics.mediumImpact();
                        if (isActive) {
                          dockState.onReactionRemoved?.call();
                        } else {
                          dockState.onReactionSelected?.call(emoji);
                        }
                        ref
                            .read(dynamicDockProvider.notifier)
                            .resetToNavigation();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isActive
                              ? (isDark
                                    ? Colors.white.withValues(alpha: 0.20)
                                    : Colors.black.withValues(alpha: 0.10))
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: isActive
                              ? Border.all(
                                  color: isDark ? Colors.white : Colors.black87,
                                  width: 1.5,
                                )
                              : null,
                        ),
                        child: AppEmoji(
                          emoji: emoji,
                          size: 28,
                          animate: true,
                          enableTapAnimation: true,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(width: 4),

          // Morph to Full Emoji Picker (+)
          GestureDetector(
            onTap: () {
              SafeHaptics.lightImpact();
              ref
                  .read(dynamicDockProvider.notifier)
                  .openEmojiPicker(
                    title: 'Choose Reaction',
                    initialCategory: EmojiCategory.system,
                    onEmojiSelected: (emoji) {
                      if (activeEmoji == emoji.code) {
                        dockState.onReactionRemoved?.call();
                      } else {
                        dockState.onReactionSelected?.call(emoji.code);
                      }
                    },
                  );
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.06),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                  width: 0.8,
                ),
              ),
              child: Icon(
                LucideIcons.plus,
                size: 18,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 1. FULL MORPHING COMMENTS DOCK
  // ==========================================
  Widget _buildMorphingCommentsDock(DynamicDockState dockState) {
    final postId = dockState.commentsPostId ?? '';

    return SizedBox.expand(
      key: ValueKey('comments_dock_$postId'),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 250) {
            SafeHaptics.lightImpact();
            dockState.onCommentClose?.call();
            ref.read(dynamicDockProvider.notifier).resetToNavigation();
          }
        },
        child: CommentBottomSheet(
          postId: postId,
          onCommentCountChanged: dockState.onCommentCountChanged,
          onClose: () {
            SafeHaptics.lightImpact();
            dockState.onCommentClose?.call();
            ref.read(dynamicDockProvider.notifier).resetToNavigation();
          },
        ),
      ),
    );
  }

  // ==========================================
  // 1.5. FULL MORPHING NEW CHAT DOCK
  // ==========================================
  Widget _buildMorphingNewChatDock(DynamicDockState dockState) {
    return SizedBox.expand(
      key: const ValueKey('new_chat_dock'),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 250) {
            SafeHaptics.lightImpact();
            dockState.onNewChatClose?.call();
            ref.read(dynamicDockProvider.notifier).resetToNavigation();
          }
        },
        child: NewChatDockPanel(
          onClose: () {
            SafeHaptics.lightImpact();
            dockState.onNewChatClose?.call();
            ref.read(dynamicDockProvider.notifier).resetToNavigation();
          },
        ),
      ),
    );
  }

  // ==========================================
  // 1.6. FULL MORPHING SHARE DOCK
  // ==========================================
  Widget _buildMorphingShareDock(DynamicDockState dockState) {
    final postId = dockState.sharePostId ?? '';

    return SizedBox.expand(
      key: ValueKey('share_dock_$postId'),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 250) {
            SafeHaptics.lightImpact();
            dockState.onShareClose?.call();
            ref.read(dynamicDockProvider.notifier).resetToNavigation();
          }
        },
        child: _MorphingShareDockContent(
          dockState: dockState,
          onClose: () {
            SafeHaptics.lightImpact();
            dockState.onShareClose?.call();
            ref.read(dynamicDockProvider.notifier).resetToNavigation();
          },
        ),
      ),
    );
  }

  // ==========================================
  // 2. CONTEXTUAL SELECTION DOCK
  // ==========================================
  Widget _buildSelectionDock(DynamicDockState dockState, bool isDark) {
    final title =
        dockState.selectionTitle ?? '${dockState.selectionCount} Selected';
    final isScrolled = dockState.isScrolled;

    return Container(
      key: const ValueKey('selection_dock'),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Cancel / Close (X) button
          GestureDetector(
            onTap: () {
              SafeHaptics.lightImpact();
              dockState.onSelectionCancel?.call();
              ref.read(dynamicDockProvider.notifier).resetToNavigation();
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: isScrolled ? 0.16 : 0.12)
                    : Colors.black.withValues(alpha: isScrolled ? 0.08 : 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.x,
                size: 18,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Selection Count / Title
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Text(
                title,
                key: ValueKey(title),
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: isDark
                      ? Colors.white
                      : (isScrolled
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF111827)),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Popout tools trigger button (if extra popout tools provided)
          if (dockState.popoutItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () {
                  SafeHaptics.lightImpact();
                  ref.read(dynamicDockProvider.notifier).togglePopout();
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: dockState.isPopoutOpen
                        ? (isDark ? Colors.white24 : Colors.black12)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.sparkles,
                    size: 18,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            ),

          // Action buttons (Delete, Share, Pin, Post, etc.)
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: dockState.selectionActions.map((action) {
                  if (action.isPrimary) {
                    final primaryTextCol = LiquidGlassTheme.primaryTextColor(
                      context,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: LiquidGlassButton(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        label: action.label ?? '',
                        icon: Icon(
                          action.icon,
                          size: 16,
                          color: primaryTextCol,
                        ),
                        onPressed: action.onTap,
                      ),
                    );
                  }

                  final color = action.isDestructive
                      ? Colors.redAccent
                      : (isDark ? Colors.white : const Color(0xFF111827));

                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: GestureDetector(
                      onTap: () {
                        SafeHaptics.mediumImpact();
                        action.onTap();
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: action.isDestructive
                              ? Colors.redAccent.withValues(
                                  alpha: isDark ? 0.18 : 0.10,
                                )
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.10)
                                    : Colors.black.withValues(alpha: 0.05)),
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(action.icon, size: 18, color: color),
                            if (action.badge != null)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.blueAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2.5. PHOTO VIEWER ACTION DOCK
  // ==========================================
  Widget _buildPhotoViewerDock(DynamicDockState dockState, bool isDark) {
    return Container(
      key: const ValueKey('photo_viewer_dock'),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPhotoActionButton(
            icon: PhosphorIconsRegular.magicWand,
            label: 'Edit',
            isDark: isDark,
            onTap: () => dockState.onPhotoEdit?.call(),
          ),
          _buildPhotoActionButton(
            icon: PhosphorIconsRegular.shareNetwork,
            label: 'Share',
            isDark: isDark,
            onTap: () => dockState.onPhotoShare?.call(),
          ),
          _buildPhotoActionButton(
            icon: PhosphorIconsFill.paperPlaneTilt,
            label: 'Post',
            isPrimary: true,
            isDark: isDark,
            onTap: () => dockState.onPhotoPost?.call(),
          ),
          _buildPhotoActionButton(
            icon: PhosphorIconsRegular.trash,
            label: 'Delete',
            isDestructive: true,
            isDark: isDark,
            onTap: () => dockState.onPhotoDelete?.call(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool isDestructive = false,
    required bool isDark,
  }) {
    if (isPrimary) {
      return LiquidGlassButton(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        label: label,
        icon: Icon(icon, size: 16, color: Colors.white),
        onPressed: onTap,
      );
    }

    final Color iconColor = isDestructive ? Colors.redAccent : Colors.white;
    final Color bgColor = isDestructive
        ? Colors.redAccent.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.10);

    return GestureDetector(
      onTap: () {
        SafeHaptics.lightImpact();
        onTap();
      },
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(19),
          border: isDestructive
              ? Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.3),
                  width: 1.0,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: iconColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 3. QUICK COMMENT / REPLY INPUT DOCK
  // ==========================================
  Widget _buildQuickCommentDock(DynamicDockState dockState, bool isDark) {
    return Container(
      key: const ValueKey('quick_comment_dock'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Close button (X)
          GestureDetector(
            onTap: () {
              SafeHaptics.lightImpact();
              _commentTextController.clear();
              _commentFocusNode.unfocus();
              dockState.onCommentClose?.call();
              ref.read(dynamicDockProvider.notifier).resetToNavigation();
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.x,
                size: 18,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Text Field
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              color: Colors.transparent,
              child: TextField(
                controller: _commentTextController,
                focusNode: _commentFocusNode,
                autofocus: true,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: dockState.commentPlaceholder,
                  hintStyle: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: (text) {
                  if (text.trim().isNotEmpty) {
                    SafeHaptics.mediumImpact();
                    dockState.onCommentSend?.call(text.trim());
                    _commentTextController.clear();
                  }
                },
              ),
            ),
          ),

          // Popout tools trigger button (e.g. Emoji, Camera, Voice)
          if (dockState.popoutItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: GestureDetector(
                onTap: () {
                  SafeHaptics.lightImpact();
                  ref.read(dynamicDockProvider.notifier).togglePopout();
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: dockState.isPopoutOpen
                        ? (isDark ? Colors.white24 : Colors.black12)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.sparkles,
                    size: 18,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            ),

          // Send / Submit Button with Spring Scale Animation
          AnimatedScale(
            scale: _hasCommentText ? 1.0 : 0.82,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            child: Padding(
              padding: const EdgeInsets.only(left: 6),
              child: LiquidGlassIconButton(
                icon: LucideIcons.arrowUp,
                size: 38,
                isPrimary: _hasCommentText,
                onPressed: () {
                  final text = _commentTextController.text.trim();
                  if (text.isNotEmpty) {
                    SafeHaptics.mediumImpact();
                    dockState.onCommentSend?.call(text);
                    _commentTextController.clear();
                  }
                },
                tooltip: 'Send comment',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. STANDARD 5-TAB NAVIGATION DOCK
  // ==========================================
  Widget _buildNavigationDock(bool isDark, double barRadius, bool isScrolled) {
    final pfpUrl = ref.watch(
      profileControllerProvider.select(
        (s) => s.asData?.value['profile_picture_url'] as String?,
      ),
    );

    const int totalFlex = _selectedNavFlex + (_unselectedNavFlex * 4); // 59

    return LayoutBuilder(
      key: const ValueKey('nav_dock'),
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final itemWidth = totalWidth * _selectedNavFlex / totalFlex;
        final itemLeft =
            (totalWidth * (widget.selectedIndex * _unselectedNavFlex)) /
            totalFlex;

        return Stack(
          children: [
            // 1. Sliding selection indicator - takes all height with higher selected width
            AnimatedPositioned(
              duration: BubbleTransitionDurations.tabSwitch,
              curve: BubbleCurves.morphCurve,
              left: itemLeft + 2.0,
              top: 2.5,
              bottom: 2.5,
              width: itemWidth - 4.0,
              child: LiquidBubblePill(
                radius: (barRadius - 2.5).clamp(0.0, double.infinity),
                isDark: isDark,
              ),
            ),

            // 2. Row of navigation items with expanded selected width
            Row(
              children: [
                _buildNavItem(
                  context: context,
                  index: 0,
                  width:
                      totalWidth *
                      (widget.selectedIndex == 0
                          ? _selectedNavFlex
                          : _unselectedNavFlex) /
                      totalFlex,
                  label: 'Home',
                  isSelected: widget.selectedIndex == 0,
                  isDark: isDark,
                  isScrolled: isScrolled,
                  icon: _buildHomeIcon(
                    isSelected: widget.selectedIndex == 0,
                    isDark: isDark,
                    isScrolled: isScrolled,
                  ),
                ),
                _buildNavItem(
                  context: context,
                  index: 1,
                  width:
                      totalWidth *
                      (widget.selectedIndex == 1
                          ? _selectedNavFlex
                          : _unselectedNavFlex) /
                      totalFlex,
                  label: 'Explore',
                  isSelected: widget.selectedIndex == 1,
                  isDark: isDark,
                  isScrolled: isScrolled,
                  icon: _buildExploreIcon(
                    isSelected: widget.selectedIndex == 1,
                    isDark: isDark,
                    isScrolled: isScrolled,
                  ),
                ),
                _buildNavItem(
                  context: context,
                  index: 2,
                  width:
                      totalWidth *
                      (widget.selectedIndex == 2
                          ? _selectedNavFlex
                          : _unselectedNavFlex) /
                      totalFlex,
                  label: 'Gallery',
                  isSelected: widget.selectedIndex == 2,
                  isDark: isDark,
                  isScrolled: isScrolled,
                  icon: _buildGalleryIcon(
                    isSelected: widget.selectedIndex == 2,
                    isDark: isDark,
                    isScrolled: isScrolled,
                  ),
                ),
                _buildNavItem(
                  context: context,
                  index: 3,
                  width:
                      totalWidth *
                      (widget.selectedIndex == 3
                          ? _selectedNavFlex
                          : _unselectedNavFlex) /
                      totalFlex,
                  label: 'Inbox',
                  isSelected: widget.selectedIndex == 3,
                  isDark: isDark,
                  isScrolled: isScrolled,
                  icon: _buildInboxIcon(
                    isSelected: widget.selectedIndex == 3,
                    isDark: isDark,
                    isScrolled: isScrolled,
                  ),
                ),
                _buildNavItem(
                  context: context,
                  index: 4,
                  width:
                      totalWidth *
                      (widget.selectedIndex == 4
                          ? _selectedNavFlex
                          : _unselectedNavFlex) /
                      totalFlex,
                  label: 'Profile',
                  isSelected: widget.selectedIndex == 4,
                  isDark: isDark,
                  isScrolled: isScrolled,
                  icon: _buildProfileIcon(
                    isSelected: widget.selectedIndex == 4,
                    pfpUrl: pfpUrl,
                    isDark: isDark,
                    isScrolled: isScrolled,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required double width,
    required String label,
    required bool isSelected,
    required bool isDark,
    required bool isScrolled,
    required Widget icon,
  }) {
    final Color selectedColor = isDark ? Colors.white : const Color(0xFF0F172A);

    final Widget labelText = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      style: TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: selectedColor,
        height: 1.1,
      ),
    );

    final Widget navContent = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedScale(
          scale: isSelected ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: icon,
        ),
        Flexible(
          fit: FlexFit.loose,
          child: ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.centerLeft,
              child: isSelected
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(width: 5),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 1.0),
                            child: labelText,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );

    return AnimatedContainer(
      duration: BubbleTransitionDurations.tabSwitch,
      curve: BubbleCurves.morphCurve,
      width: width,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          SafeHaptics.lightImpact();
          widget.onItemTapped(index);
        },
        child: SizedBox(
          height: double.infinity,
          child: Center(child: navContent),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon(
    IconData iconData, {
    required bool isSelected,
    required bool isDark,
    required bool isScrolled,
  }) {
    if (isSelected) {
      return Icon(
        iconData,
        size: 22,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      );
    }

    final unselectedColor = isDark
        ? (isScrolled ? Colors.white60 : Colors.white54)
        : (isScrolled ? const Color(0xFF475569) : const Color(0xFF64748B));

    return Icon(iconData, size: 22, color: unselectedColor);
  }

  Widget _buildHomeIcon({
    required bool isSelected,
    required bool isDark,
    required bool isScrolled,
  }) {
    return _buildAnimatedIcon(
      LucideIcons.home,
      isSelected: isSelected,
      isDark: isDark,
      isScrolled: isScrolled,
    );
  }

  Widget _buildExploreIcon({
    required bool isSelected,
    required bool isDark,
    required bool isScrolled,
  }) {
    return _buildAnimatedIcon(
      LucideIcons.compass,
      isSelected: isSelected,
      isDark: isDark,
      isScrolled: isScrolled,
    );
  }

  Widget _buildGalleryIcon({
    required bool isSelected,
    required bool isDark,
    required bool isScrolled,
  }) {
    return _buildAnimatedIcon(
      LucideIcons.flower,
      isSelected: isSelected,
      isDark: isDark,
      isScrolled: isScrolled,
    );
  }

  Widget _buildInboxIcon({
    required bool isSelected,
    required bool isDark,
    required bool isScrolled,
  }) {
    return _buildAnimatedIcon(
      LucideIcons.inbox,
      isSelected: isSelected,
      isDark: isDark,
      isScrolled: isScrolled,
    );
  }

  Widget _buildProfileIcon({
    required bool isSelected,
    required String? pfpUrl,
    required bool isDark,
    required bool isScrolled,
  }) {
    const double size = 23.0;

    Widget avatarImage = (pfpUrl != null && pfpUrl.trim().isNotEmpty)
        ? UserAvatar(imageUrl: pfpUrl, radius: size / 2)
        : Container(
            color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
            child: Icon(
              LucideIcons.user,
              size: 14,
              color: isSelected
                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                  : (isDark ? Colors.white60 : const Color(0xFF64748B)),
            ),
          );

    if (isSelected) {
      return Container(
        width: size + 4,
        height: size + 4,
        padding: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LiquidGlassTheme.bubbleBlueGradient,
          boxShadow: [
            BoxShadow(
              color: LiquidGlassTheme.bubbleBlue.withValues(alpha: 0.12),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipOval(child: avatarImage),
      );
    }

    return Container(
      width: size + 4,
      height: size + 4,
      padding: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
          width: 1.2,
        ),
      ),
      child: ClipOval(child: avatarImage),
    );
  }
}

class _MorphingShareDockContent extends ConsumerStatefulWidget {
  final DynamicDockState dockState;
  final VoidCallback? onClose;

  const _MorphingShareDockContent({required this.dockState, this.onClose});

  @override
  ConsumerState<_MorphingShareDockContent> createState() =>
      _MorphingShareDockContentState();
}

class _MorphingShareDockContentState
    extends ConsumerState<_MorphingShareDockContent> {
  List<dynamic> _friends = [];
  bool _loading = true;
  String? _error;
  final Set<String> _sentUserIds = {};

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  Future<void> _fetchFriends() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await ref.read(friendRemoteDataSourceProvider).getFriends();
      if (mounted) {
        setState(() {
          _friends = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Failed to load friends.";
          _loading = false;
        });
      }
    }
  }

  void _handleClose() {
    SafeHaptics.lightImpact();
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      widget.dockState.onShareClose?.call();
      ref.read(dynamicDockProvider.notifier).resetToNavigation();
    }
  }

  void _shareViaSystem(String postId) {
    SafeHaptics.lightImpact();
    _handleClose();
    SharePlus.instance.share(
      ShareParams(
        text: 'Check out this post on Bubble! https://bubble.app/post/$postId',
      ),
    );
  }

  void _sendToFriend(String friendId, String friendName) {
    SafeHaptics.mediumImpact();
    setState(() {
      _sentUserIds.add(friendId);
    });
    UiHelpers.showSuccess(context, "Sent to $friendName");
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        _handleClose();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final postId = widget.dockState.sharePostId ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: OverflowBox(
        minHeight: 0,
        maxHeight: 240,
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: 240,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Clean Upper Header (Title + Close X button, NO useless line!)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 14, 6),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.share2,
                      size: 18,
                      color: LiquidGlassTheme.textPrimary(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Share to...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: LiquidGlassTheme.textPrimary(context),
                      ),
                    ),
                    if (_friends.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.16)
                                : Colors.black.withValues(alpha: 0.08),
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          '${_friends.length}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: LiquidGlassTheme.textPrimary(context),
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    GestureDetector(
                      onTap: _handleClose,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.10)
                              : Colors.black.withValues(alpha: 0.05),
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

              // 2. Horizontal Friends Grid using SmartUserAvatar
              SizedBox(
                height: 104,
                child: _loading
                    ? Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: LiquidGlassTheme.textPrimary(context),
                          ),
                        ),
                      )
                    : _error != null
                    ? Center(
                        child: GestureDetector(
                          onTap: _fetchFriends,
                          child: Text(
                            'Tap to retry',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: LiquidGlassTheme.textSecondary(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    : _friends.isEmpty
                    ? Center(
                        child: Text(
                          'No friends found',
                          style: TextStyle(
                            fontSize: 13,
                            color: LiquidGlassTheme.textSecondary(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        itemCount: _friends.length,
                        itemBuilder: (context, index) {
                          final friend = _friends[index];
                          final friendId =
                              (friend['friend_id'] ??
                                      friend['user_id'] ??
                                      friend['target_user_id'] ??
                                      friend['id'] ??
                                      '')
                                  .toString();
                          final friendName =
                              (friend['friend_username'] ??
                                      friend['username'] ??
                                      friend['first_name'] ??
                                      'Friend')
                                  .toString();
                          final isSent = _sentUserIds.contains(friendId);

                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: isSent
                                  ? null
                                  : () => _sendToFriend(friendId, friendName),
                              behavior: HitTestBehavior.opaque,
                              child: SizedBox(
                                width: 66,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        SmartUserAvatar(
                                          userId: friendId,
                                          radius: 25,
                                          showUsername: false,
                                        ),
                                        if (isSent)
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.65,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              LucideIcons.check,
                                              size: 24,
                                              color: Colors.greenAccent,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      isSent ? 'Sent' : friendName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: isSent
                                            ? Colors.greenAccent
                                            : LiquidGlassTheme.textPrimary(
                                                context,
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const Spacer(),

              // 3. System Share Button ("Share via...")
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: GestureDetector(
                  onTap: () => _shareViaSystem(postId),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: LiquidGlassTheme.pillBackground(
                        context,
                        isSelected: true,
                      ),
                      borderRadius: BorderRadius.circular(23),
                      border: Border.all(
                        color: LiquidGlassTheme.pillBorderColor(
                          context,
                          isSelected: true,
                        ),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.share,
                          size: 16,
                          color: LiquidGlassTheme.textPrimary(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Share via...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                            color: LiquidGlassTheme.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
