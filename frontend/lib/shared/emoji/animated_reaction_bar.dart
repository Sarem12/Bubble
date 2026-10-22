import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../core/utils/safe_haptics.dart';
import '../providers/dynamic_dock_provider.dart';
import 'app_emoji.dart';
import 'bubble_emoji_picker.dart';
import 'bubble_emoji.dart';
import '../widgets/liquid_glass.dart';
import '../../features/profile/presentation/controllers/settings_controller.dart';

/// A sleek floating animated reaction bar (like Telegram / Instagram / iMessage).
/// Features staggered pop-in entrance, animated emojis, and a "+" button
/// that expands the full animated BubbleEmojiPicker!
class AnimatedReactionBar extends StatefulWidget {
  final String? activeEmoji;
  final ValueChanged<String> onReact;
  final VoidCallback? onRemoveReaction;
  final VoidCallback? onMoreTap;
  final List<String> topEmojis;

  const AnimatedReactionBar({
    super.key,
    this.activeEmoji,
    required this.onReact,
    this.onRemoveReaction,
    this.onMoreTap,
    this.topEmojis = const ['❤️', '😂', '🔥', '👍', '😮'],
  });

  /// Show the reaction bar inside the Dynamic Liquid Dock
  static Future<void> showModal(
    BuildContext context, {
    String? activeEmoji,
    required ValueChanged<String> onReact,
    VoidCallback? onRemoveReaction,
    VoidCallback? onMoreTap,
  }) async {
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      container
          .read(dynamicDockProvider.notifier)
          .openReactionBar(
        activeEmoji: activeEmoji,
        onReact: onReact,
        onRemoveReaction: onRemoveReaction,
      );
      return;
    } catch (_) {
      return showBubbleModalBottomSheet(
        context: context,
        builder: (ctx) => SafeArea(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: AnimatedReactionBar(
              activeEmoji: activeEmoji,
              topEmojis: _configuredReactions(context),
              onReact: (emoji) {
                Navigator.of(ctx).pop();
                onReact(emoji);
              },
              onRemoveReaction: () {
                Navigator.of(ctx).pop();
                onRemoveReaction?.call();
              },
              onMoreTap: onMoreTap,
            ),
          ),
        ),
      );
    }
  }

  static List<String> _configuredReactions(BuildContext context) {
    try {
      final saved = ProviderScope.containerOf(
        context,
        listen: false,
      ).read(settingsControllerProvider).value?.topReactions;
      return saved == null || saved.isEmpty
          ? const ['❤️', '😂', '🔥', '👍', '😮']
          : saved;
    } catch (_) {
      return const ['❤️', '😂', '🔥', '👍', '😮'];
    }
  }

  @override
  State<AnimatedReactionBar> createState() => _AnimatedReactionBarState();
}

class _AnimatedReactionBarState extends State<AnimatedReactionBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _openFullPicker() {
    SafeHaptics.lightImpact();
    if (widget.onMoreTap != null) {
      widget.onMoreTap!();
      return;
    }
    BubbleEmojiPicker.showModal(
      context,
      initialCategory: EmojiCategory.system,
      onEmojiSelected: (BubbleEmoji emoji) {
        if (widget.activeEmoji == emoji.code) {
          widget.onRemoveReaction?.call();
        } else {
          widget.onReact(emoji.code);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LiquidGlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      borderRadius: BorderRadius.circular(32),
      blur: 16,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Staggered pop-in reaction items
          ...List.generate(widget.topEmojis.length, (index) {
            final emoji = widget.topEmojis[index];
            final isActive = widget.activeEmoji == emoji;

            // Staggered interval
            final start = (index * 0.1).clamp(0.0, 0.6);
            final end = (start + 0.4).clamp(0.0, 1.0);
            final curve = CurvedAnimation(
              parent: _entranceController,
              curve: Interval(start, end, curve: Curves.easeOutBack),
            );

            return ScaleTransition(
              scale: curve,
              child: _ReactionItem(
                emoji: emoji,
                isActive: isActive,
                onTap: () {
                  SafeHaptics.lightImpact();
                  if (isActive) {
                    widget.onRemoveReaction?.call();
                  } else {
                    widget.onReact(emoji);
                  }
                },
              ),
            );
          }),

          // Expand / More "+" Button
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _entranceController,
              curve: const Interval(0.6, 1.0, curve: Curves.easeOutBack),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Material(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _openFullPicker,
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    child: Icon(
                      PhosphorIconsRegular.plus,
                      size: 20,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionItem extends StatefulWidget {
  final String emoji;
  final bool isActive;
  final VoidCallback onTap;

  const _ReactionItem({
    required this.emoji,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_ReactionItem> createState() => _ReactionItemState();
}

class _ReactionItemState extends State<_ReactionItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _tapAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.35,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.35,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_tapAnim);
  }

  @override
  void dispose() {
    _tapAnim.dispose();
    super.dispose();
  }

  void _handleTap() {
    _tapAnim.forward(from: 0.0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: widget.isActive
                ? (isDark
                      ? Colors.white.withValues(alpha: 0.20)
                      : Colors.black.withValues(alpha: 0.10))
                : Colors.transparent,
            shape: BoxShape.circle,
            border: widget.isActive
                ? Border.all(
                    color: isDark ? Colors.white : Colors.black87,
                    width: 1.5,
                  )
                : null,
          ),
          child: AppEmoji(emoji: widget.emoji, size: 30, animate: true),
        ),
      ),
    );
  }
}
