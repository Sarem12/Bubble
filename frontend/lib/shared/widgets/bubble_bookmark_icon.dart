import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'liquid_glass.dart';

/// Custom Painter that renders a 3D soap-bubble liquid glass bookmark:
/// 1. Prismatic two-tier ambient iridescent glow (diffuse cyan-blue halo + warm magenta aura)
/// 2. Crystal glass body filled with fluid, non-linear chromatic gradient
/// 3. Delicate thin-film rainbow sheen across the surface
/// 4. Convex 3D specular curved dome glint with secondary shoulder catchlight
/// 5. Bottom ambient ground-bounce reflection at ribbon tips
/// 6. Razor-sharp directional specular crystalline border rim
class LucideBookmarkFillPainter extends CustomPainter {
  final Color? color;
  final Gradient? gradient;
  final bool hasGlow;
  final bool isDark;

  LucideBookmarkFillPainter({
    this.color,
    this.gradient,
    this.hasGlow = true,
    this.isDark = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    final r = 2.0 * scale;

    // Exact Lucide Bookmark SVG Path:
    // M 19 21 L 12 17 L 5 21 V 5 A 2 2 0 0 1 7 3 H 17 A 2 2 0 0 1 19 5 V 21 Z
    final path = Path();
    path.moveTo(7.0 * scale, 3.0 * scale);
    path.lineTo(17.0 * scale, 3.0 * scale);
    path.arcToPoint(
      Offset(19.0 * scale, 5.0 * scale),
      radius: Radius.circular(r),
      clockwise: true,
    );
    path.lineTo(19.0 * scale, 21.0 * scale);
    path.lineTo(12.0 * scale, 17.0 * scale);
    path.lineTo(5.0 * scale, 21.0 * scale);
    path.lineTo(5.0 * scale, 5.0 * scale);
    path.arcToPoint(
      Offset(7.0 * scale, 3.0 * scale),
      radius: Radius.circular(r),
      clockwise: true,
    );
    path.close();

    final shaderRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // 1. Two-tier ambient iridescent glow (diffuse blue halo + warm magenta aura)
    if (hasGlow) {
      final deepGlow = Paint()
        ..style = PaintingStyle.fill
        ..color = LiquidGlassTheme.bubbleBlue.withValues(alpha: isDark ? 0.32 : 0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 7.0 * scale);
      canvas.drawPath(path, deepGlow);

      final warmGlow = Paint()
        ..style = PaintingStyle.fill
        ..color = LiquidGlassTheme.bubbleMagenta.withValues(alpha: isDark ? 0.30 : 0.20)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.5 * scale);
      canvas.drawPath(path, warmGlow);
    }

    // 2. Base crystal glass body with fluid non-linear gradient
    final effectiveGradient = gradient ??
        (isDark ? LiquidGlassTheme.bubbleIconGradient : LiquidGlassTheme.bubbleIconLightGradient);
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = effectiveGradient.createShader(shaderRect);
    canvas.drawPath(path, fillPaint);

    // 3. Delicate iridescent thin-film rainbow sheen across surface
    final sheenPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          LiquidGlassTheme.bubbleMagenta.withValues(alpha: isDark ? 0.16 : 0.12),
          LiquidGlassTheme.bubbleBlue.withValues(alpha: isDark ? 0.18 : 0.14),
          LiquidGlassTheme.bubbleGreen.withValues(alpha: isDark ? 0.12 : 0.08),
        ],
        stops: const [0.0, 0.50, 1.0],
      ).createShader(shaderRect);
    canvas.drawPath(path, sheenPaint);

    // 4. Curved 3D soap-bubble specular dome glint (convex curved reflection across top)
    final glintPath = Path();
    glintPath.moveTo(7.2 * scale, 3.4 * scale);
    glintPath.lineTo(16.8 * scale, 3.4 * scale);
    glintPath.arcToPoint(
      Offset(18.2 * scale, 4.8 * scale),
      radius: Radius.circular(r * 0.9),
      clockwise: true,
    );
    glintPath.lineTo(18.2 * scale, 8.2 * scale);
    // Smooth convex curved belly sweeping across the center of the ribbon
    glintPath.quadraticBezierTo(
      12.0 * scale,
      11.0 * scale,
      5.8 * scale,
      8.2 * scale,
    );
    glintPath.lineTo(5.8 * scale, 4.8 * scale);
    glintPath.arcToPoint(
      Offset(7.2 * scale, 3.4 * scale),
      radius: Radius.circular(r * 0.9),
      clockwise: true,
    );
    glintPath.close();

    final glintPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.72 : 0.40),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 11.0 * scale));
    canvas.drawPath(glintPath, glintPaint);

    // Micro specular glint pill on the top-left curved shoulder
    final microHighlightPath = Path();
    microHighlightPath.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(7.6 * scale, 4.2 * scale, 4.2 * scale, 1.6 * scale),
        Radius.circular(0.8 * scale),
      ),
    );
    final microPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: isDark ? 0.75 : 0.55);
    canvas.drawPath(microHighlightPath, microPaint);

    // 5. Bottom ambient ground-bounce reflection
    final bouncePath = Path();
    bouncePath.moveTo(5.0 * scale, 21.0 * scale);
    bouncePath.lineTo(12.0 * scale, 17.0 * scale);
    bouncePath.lineTo(19.0 * scale, 21.0 * scale);
    bouncePath.lineTo(19.0 * scale, 17.5 * scale);
    bouncePath.lineTo(12.0 * scale, 14.5 * scale);
    bouncePath.lineTo(5.0 * scale, 17.5 * scale);
    bouncePath.close();

    final bouncePaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          LiquidGlassTheme.bubbleBlue.withValues(alpha: isDark ? 0.25 : 0.20),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromLTWH(0, 14.0 * scale, size.width, 7.0 * scale));
    canvas.drawPath(bouncePath, bouncePaint);

    // 6. Directional specular crystalline border rim
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                Colors.white.withValues(alpha: 0.92),
                LiquidGlassTheme.bubbleMagenta.withValues(alpha: 0.65),
                LiquidGlassTheme.bubbleBlue.withValues(alpha: 0.55),
                LiquidGlassTheme.bubbleGreen.withValues(alpha: 0.45),
                Colors.white.withValues(alpha: 0.20),
              ]
            : [
                LiquidGlassTheme.bubbleMagenta.withValues(alpha: 0.75),
                LiquidGlassTheme.bubbleBlue.withValues(alpha: 0.70),
                LiquidGlassTheme.bubbleGreen.withValues(alpha: 0.60),
                const Color(0xFF0F172A).withValues(alpha: 0.25),
              ],
        stops: const [0.0, 0.25, 0.55, 0.85, 1.0],
      ).createShader(shaderRect);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant LucideBookmarkFillPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.gradient != gradient ||
        oldDelegate.hasGlow != hasGlow ||
        oldDelegate.isDark != isDark;
  }
}

/// Dynamic Bookmark icon widget that seamlessly toggles between
/// the outlined Lucide bookmark icon and our authentic 3D liquid bubble glass filled bookmark.
class BubbleBookmarkIcon extends StatelessWidget {
  final bool isSaved;
  final double size;
  final Color? color;
  final Gradient? gradient;
  final bool withGlassPill;

  const BubbleBookmarkIcon({
    super.key,
    required this.isSaved,
    this.size = 20.0,
    this.color,
    this.gradient,
    this.withGlassPill = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget iconWidget;
    if (!isSaved) {
      iconWidget = Icon(
        LucideIcons.bookmark,
        size: size,
        color: color ?? LiquidGlassTheme.textSecondary(context),
      );
    } else {
      final effectiveGradient = gradient ?? LiquidGlassTheme.iconGradient(context);
      iconWidget = CustomPaint(
        size: Size(size, size),
        painter: LucideBookmarkFillPainter(
          gradient: effectiveGradient,
          color: color,
          hasGlow: true,
          isDark: isDark,
        ),
      );
    }

    if (withGlassPill) {
      return Container(
        width: size + 16,
        height: size + 16,
        alignment: Alignment.center,
        child: LiquidBubblePill(
          radius: (size + 16) / 2,
          isDark: isDark,
          child: Center(child: iconWidget),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Center(child: iconWidget),
    );
  }
}
