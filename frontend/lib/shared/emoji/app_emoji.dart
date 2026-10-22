import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'bubble_emoji.dart';
import 'system_emoji_registry.dart';
import 'emoji_data.dart';

/// Universal Emoji renderer for Bubble.
/// Renders standard Unicode emojis, animated Unicode emojis,
/// and custom System emojis seamlessly.
class AppEmoji extends StatefulWidget {
  final String emoji;
  final double size;
  final bool animate;
  final bool enableTapAnimation;
  final VoidCallback? onTap;
  final TextStyle? style;

  const AppEmoji({
    super.key,
    required this.emoji,
    this.size = 24.0,
    this.animate = true,
    this.enableTapAnimation = false,
    this.onTap,
    this.style,
  });

  @override
  State<AppEmoji> createState() => _AppEmojiState();
}

class _AppEmojiState extends State<AppEmoji> with TickerProviderStateMixin {
  AnimationController? _loopController;
  AnimationController? _tapController;
  Animation<double>? _tapScale;

  BubbleEmoji? _resolvedEmoji;

  @override
  void initState() {
    super.initState();
    _resolveEmoji();

    if (widget.enableTapAnimation) {
      _initTapController();
    }

    _setupLoopAnimation();
  }

  void _initTapController() {
    _tapController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _tapScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.82)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.82, end: 1.18)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.18, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_tapController!);
  }

  void _resolveEmoji() {
    _resolvedEmoji = EmojiData.findByCode(widget.emoji);
  }

  void _setupLoopAnimation() {
    if (!widget.animate) {
      _loopController?.dispose();
      _loopController = null;
      return;
    }

    var animType = _resolvedEmoji?.animationType ?? EmojiAnimationType.pulse;
    if (animType == EmojiAnimationType.none) {
      animType = EmojiAnimationType.pulse;
    }

    // Determine loop duration based on animation type
    int durationMs = 1200;
    switch (animType) {
      case EmojiAnimationType.heartbeat:
        durationMs = 1100;
        break;
      case EmojiAnimationType.flicker:
        durationMs = 700;
        break;
      case EmojiAnimationType.bounce:
        durationMs = 900;
        break;
      case EmojiAnimationType.wobble:
        durationMs = 1200;
        break;
      case EmojiAnimationType.pulse:
        durationMs = 1400;
        break;
      case EmojiAnimationType.sparkle:
        durationMs = 1500;
        break;
      case EmojiAnimationType.spin:
        durationMs = 2800;
        break;
      default:
        durationMs = 1200;
    }

    _loopController ??= AnimationController(vsync: this);
    _loopController!.duration = Duration(milliseconds: durationMs);
    _loopController!.repeat();
  }

  @override
  void didUpdateWidget(AppEmoji oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.emoji != widget.emoji) {
      _resolveEmoji();
    }
    if (oldWidget.animate != widget.animate ||
        oldWidget.emoji != widget.emoji) {
      _setupLoopAnimation();
    }
    if (widget.enableTapAnimation && _tapController == null) {
      _initTapController();
    } else if (!widget.enableTapAnimation && _tapController != null) {
      _tapController?.dispose();
      _tapController = null;
      _tapScale = null;
    }
  }

  @override
  void dispose() {
    _loopController?.dispose();
    _tapController?.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.enableTapAnimation) {
      _tapController?.forward(from: 0.0);
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final emojiCode = widget.emoji.trim();

    // 1. Check if it's a registered System Emoji
    if (SystemEmojiRegistry.isSystemEmoji(emojiCode)) {
      final systemEmoji = SystemEmojiRegistry.get(emojiCode)!;
      Widget child;
      if (systemEmoji.customBuilder != null) {
        child = systemEmoji.customBuilder!(context, widget.size, widget.animate);
      } else {
        child = SizedBox(
          width: widget.size,
          height: widget.size,
          child: const Icon(Icons.bubble_chart, color: Colors.grey),
        );
      }

      return _wrapInteractivity(child);
    }

    // 2. Standard Unicode / Animated Unicode Emoji
    Widget content;
    final fontSize = widget.size * 0.82;
    final textWidget = Text(
      emojiCode,
      style: (widget.style ?? const TextStyle()).copyWith(
        fontSize: fontSize,
        height: 1.1,
      ),
      textAlign: TextAlign.center,
    );

    if (widget.animate && _loopController != null) {
      final animType = _resolvedEmoji?.animationType ?? EmojiAnimationType.pulse;
      content = AnimatedBuilder(
        animation: _loopController!,
        builder: (context, child) {
          final progress = _loopController!.value;
          return _applyAnimation(animType, progress, textWidget);
        },
      );
    } else {
      content = textWidget;
    }

    final sizedContent = SizedBox(
      width: widget.size,
      height: widget.size,
      child: Center(child: content),
    );

    return _wrapInteractivity(sizedContent);
  }

  Widget _applyAnimation(
      EmojiAnimationType type, double progress, Widget child) {
    switch (type) {
      case EmojiAnimationType.heartbeat:
        // Realistic ba-bump heartbeat cadence
        double scale = 1.0;
        if (progress < 0.16) {
          scale = 1.0 + 0.24 * math.sin(progress / 0.16 * math.pi);
        } else if (progress >= 0.22 && progress < 0.40) {
          scale = 1.0 + 0.16 * math.sin((progress - 0.22) / 0.18 * math.pi);
        }
        return Transform.scale(scale: scale, child: child);

      case EmojiAnimationType.bounce:
        final bounceOffset = -math.sin(progress * math.pi) * (widget.size * 0.22);
        final squash = 1.0 + (progress > 0.8 ? 0.08 * math.sin((progress - 0.8) / 0.2 * math.pi) : 0.0);
        return Transform.translate(
          offset: Offset(0, bounceOffset),
          child: Transform.scale(
            scaleX: squash,
            scaleY: 2.0 - squash,
            child: child,
          ),
        );

      case EmojiAnimationType.wobble:
        final angle = math.sin(progress * 2 * math.pi) * 0.18;
        return Transform.rotate(angle: angle, child: child);

      case EmojiAnimationType.flicker:
        final jitterX = (math.sin(progress * 8 * math.pi)) * 0.8;
        final jitterScale = 1.0 + 0.12 * math.cos(progress * 6 * math.pi);
        return Transform.translate(
          offset: Offset(jitterX, 0),
          child: Transform.scale(scale: jitterScale, child: child),
        );

      case EmojiAnimationType.sparkle:
        final scale = 1.0 + 0.15 * math.sin(progress * 2 * math.pi);
        final opacity = 0.85 + 0.15 * math.cos(progress * 2 * math.pi);
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(scale: scale, child: child),
        );

      case EmojiAnimationType.spin:
        return Transform.rotate(angle: progress * 2 * math.pi, child: child);

      case EmojiAnimationType.pulse:
      default:
        final scale = 1.0 + 0.14 * math.sin(progress * 2 * math.pi);
        return Transform.scale(scale: scale, child: child);
    }
  }

  Widget _wrapInteractivity(Widget child) {
    Widget result = child;

    if (widget.enableTapAnimation && _tapController != null && _tapScale != null) {
      result = AnimatedBuilder(
        animation: _tapController!,
        builder: (context, c) => Transform.scale(
          scale: _tapScale!.value,
          child: c,
        ),
        child: result,
      );
    }

    if (widget.onTap != null || widget.enableTapAnimation) {
      result = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: result,
      );
    }

    return result;
  }
}
