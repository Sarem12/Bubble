import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../app/routes.dart';
import '../../core/utils/safe_haptics.dart';
export 'bubble_bookmark_icon.dart';

/// Style tokens and color helpers for the Liquid Glass fluid design language.
/// Perfectly harmonized with [AppNavBar].
class LiquidGlassTheme {
  // --- The Signature Bubble Iridescent Palette ---
  static const Color bubbleMagenta = Color(0xFFC913B9); // #C913B9
  static const Color bubbleBlue = Color(0xFF1781E6);    // #1781E6
  static const Color bubbleGreen = Color(0xFF01E762);   // #01E762

  /// Shared translucent surface used by floating navigation and dock controls.
  static LinearGradient dockSurfaceGradient({
    required bool isDark,
    bool emphasized = false,
  }) {
    final lightAdjustment = isDark ? 0.0 : 0.14;
    final emphasisAdjustment = emphasized ? 0.14 : 0.0;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              const Color(0xFF242832).withValues(
                alpha: 0.48 + emphasisAdjustment,
              ),
              const Color(0xFF111827).withValues(
                alpha: 0.36 + emphasisAdjustment,
              ),
            ]
          : [
              Colors.white.withValues(
                alpha: 0.64 + lightAdjustment + emphasisAdjustment,
              ),
              const Color(0xFFF8FAFC).withValues(
                alpha: 0.52 + lightAdjustment + emphasisAdjustment,
              ),
            ],
    );
  }

  static Color dockSurfaceBorder({required bool isDark}) => isDark
      ? Colors.white.withValues(alpha: 0.24)
      : Colors.white.withValues(alpha: 0.82);

  /// Layered ambient shadows keep the floating surfaces visible on pure black.
  static List<BoxShadow> dockSurfaceShadows({
    required bool isDark,
    bool isScrolled = false,
  }) => [
    BoxShadow(
      color: Colors.black.withValues(
        alpha: isDark
            ? (isScrolled ? 0.56 : 0.46)
            : (isScrolled ? 0.14 : 0.10),
      ),
      blurRadius: isScrolled ? 28 : 24,
      offset: Offset(0, isScrolled ? 8 : 6),
    ),
    BoxShadow(
      color: bubbleBlue.withValues(alpha: isDark ? 0.16 : 0.07),
      blurRadius: isDark ? 22 : 16,
      offset: const Offset(0, 2),
    ),
    if (isDark)
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.075),
        blurRadius: 7,
        offset: const Offset(0, -1),
      ),
  ];

  /// Low-opacity color play that reads as a glass reflection without tinting text.
  static LinearGradient dockSurfaceSheen({required bool isDark}) =>
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          bubbleMagenta.withValues(alpha: isDark ? 0.035 : 0.045),
          bubbleBlue.withValues(alpha: isDark ? 0.025 : 0.035),
          bubbleGreen.withValues(alpha: isDark ? 0.02 : 0.03),
        ],
        stops: const [0.0, 0.52, 1.0],
      );

  /// 3-color signature mixed Bubble gradient (#C913B9 -> #1781E6 -> #01E762)
  /// Standard diagonal angle from topLeft to bottomRight.
  static const LinearGradient bubbleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      bubbleMagenta,
      bubbleBlue,
      bubbleGreen,
    ],
    stops: [0.0, 0.48, 1.0],
  );

  /// Horizontal 3-color Bubble gradient (left-to-right)
  static const LinearGradient bubbleGradientHorizontal = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      bubbleMagenta,
      bubbleBlue,
      bubbleGreen,
    ],
    stops: [0.0, 0.48, 1.0],
  );

  /// Signature Liquid Bubble Blue with subtle soap-bubble rim refractions.
  /// 45-degree diagonal flow engineered with a non-linear S-curve (smoothstep) system:
  /// - Non-linear ease-in/ease-out eliminates hard creases and linear color banding.
  /// - Top-left: Delicate luminous pink catchlight dissolving with zero slope into Bubble Blue.
  /// - Core: Uninterrupted, solid signature Bubble Blue (#1781E6) across the main body.
  /// - Bottom-right: Smooth, non-linear ease-out into spring green refraction (#10B981).
  static const LinearGradient bubbleBlueGradient = LinearGradient(
    begin: Alignment(-0.35, -2.0),
    end: Alignment(0.35, 2.0),
    colors: [
      Color(0xFFE879F9), // 0.000: Luminous pink catchlight
      Color(0xFFDD7AF7), // 0.044: Non-linear ease-in start (gentle slope)
      Color(0xFFBF7CF3), // 0.088: Soft lilac transition
      Color(0xFF917EED), // 0.132: Periwinkle inflection point
      Color(0xFF5580E8), // 0.176: Royal blue ease-out
      Color(0xFF1781E6), // 0.220: Zero-slope entry into Bubble Blue
      bubbleBlue,        // 0.800: Solid Bubble Blue core through body
      Color(0xFF1688DE), // 0.840: Deep blue ease-in towards green
      Color(0xFF1598C9), // 0.880: Ocean teal inflection
      Color(0xFF13A8AD), // 0.920: Soft seafoam
      Color(0xFF11B490), // 0.960: Minty spring green ease-out
      Color(0xFF10B981), // 1.000: Zero-slope landing in Spring Green
    ],
    stops: [
      0.0,
      0.044,
      0.088,
      0.132,
      0.176,
      0.220,
      0.800,
      0.840,
      0.880,
      0.920,
      0.960,
      1.0,
    ],
  );

  /// Telegram-style continuous screen-space vertical gradient for chat messages.
  /// Flows non-linearly using an S-curve easing system from vibrant fuchsia/pink,
  /// smoothly decelerating through electric Bubble blue, and landing into spring green.
  static LinearGradient continuousChatGradient({required bool isDark}) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? const [
              Color(0xFFE879F9), // 0.000: Luminous fuchsia/pink
              Color(0xFFD77AF6), // 0.125: Non-linear ease-in
              Color(0xFFAA7DF0), // 0.250: Soft lavender inflection
              Color(0xFF6580E9), // 0.375: Royal periwinkle ease-out
              bubbleBlue,        // 0.500: Electric Bubble blue core
              Color(0xFF168CDA), // 0.625: Cerulean ease-in
              Color(0xFF14A0BC), // 0.750: Ocean teal inflection
              Color(0xFF11B296), // 0.875: Soft seafoam ease-out
              Color(0xFF10B981), // 1.000: Vivid spring green
            ]
          : const [
              Color(0xFFD946EF), // 0.000: High contrast fuchsia
              Color(0xFFC040F5), // 0.125: Non-linear ease-in
              Color(0xFF904BEF), // 0.250: Violet inflection
              Color(0xFF505BEA), // 0.375: Royal indigo ease-out
              Color(0xFF1269C2), // 0.500: Deep Bubble blue core
              Color(0xFF0F75AC), // 0.625: Deep cerulean
              Color(0xFF0C8095), // 0.750: Deep teal
              Color(0xFF088C7F), // 0.875: Sea green
              Color(0xFF059669), // 1.000: Emerald green
            ],
      stops: const [0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875, 1.0],
    );
  }

  /// Fluid, multi-chromatic Liquid Glass gradient engineered specifically for icons & fine glyphs.
  /// Blends soft lavender catch-lights, vivid signature magenta, electric blue,
  /// and vibrant spring green to eliminate harsh linear RGB striping.
  static const LinearGradient bubbleIconGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF0ABFC), // Luminous iridescent lavender highlight
      bubbleMagenta,     // #C913B9 Signature magenta
      bubbleBlue,        // #1781E6 Bubble blue
      bubbleGreen,       // #01E762 Neon spring green
    ],
    stops: [0.0, 0.28, 0.68, 1.0],
  );

  /// High-contrast, rich Liquid Glass gradient specifically engineered for icons & fine glyphs in light mode.
  /// Uses deep saturated tones (fuchsia-700 -> signature bubble blue -> emerald-600) so icons stay sharp,
  /// punchy, and crystal-clear on light backgrounds.
  static const LinearGradient bubbleIconLightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFA21CAF), // Rich vivid fuchsia-magenta
      Color(0xFF1781E6), // Signature Bubble blue
      Color(0xFF059669), // Crisp spring-emerald green
    ],
    stops: [0.0, 0.48, 1.0],
  );

  /// Context-aware icon gradient that provides high contrast in both light and dark modes
  static LinearGradient iconGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? bubbleIconGradient : bubbleIconLightGradient;
  }

  /// Spherical 3D soap-bubble radial refraction shader for curved glass surfaces and icons.
  static RadialGradient bubbleGlassRadialGradient({
    AlignmentGeometry center = const Alignment(-0.32, -0.42),
    double radius = 1.15,
  }) {
    return RadialGradient(
      center: center,
      radius: radius,
      colors: const [
        Color(0xFFFFFFFF), // Specular light highlight center
        Color(0xFFF472B6), // Radiant pink-magenta bloom
        bubbleMagenta,     // Signature bubble magenta
        bubbleBlue,        // Electric blue core
        bubbleGreen,       // Spring green refraction
      ],
      stops: const [0.0, 0.18, 0.45, 0.76, 1.0],
    );
  }

  /// 3D Specular curved dome glint shader for glass highlight overlays
  static const LinearGradient bubbleSpecularGlintGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xB3FFFFFF), // Crisp 70% white specular glint
      Color(0x00FFFFFF), // Transparent fade
    ],
    stops: [0.0, 0.60],
  );

  /// Vibrant Bubble gradient with custom angle & opacity eased non-linearly
  static LinearGradient bubbleGradientWith({
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
    double opacity = 1.0,
  }) {
    return createNonLinearGradient(
      begin: begin,
      end: end,
      colors: [
        bubbleMagenta.withValues(alpha: opacity),
        bubbleBlue.withValues(alpha: opacity),
        bubbleGreen.withValues(alpha: opacity),
      ],
      stops: const [0.0, 0.52, 1.0],
    );
  }

  /// Delicate iridescent bubblish thin-film reflection sheen for glass & specular highlights
  static LinearGradient bubbleReflectionGradient({
    double opacity = 0.12,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return createNonLinearGradient(
      begin: begin,
      end: end,
      colors: [
        bubbleMagenta.withValues(alpha: opacity * 0.9),
        bubbleBlue.withValues(alpha: opacity * 1.1),
        bubbleGreen.withValues(alpha: opacity * 0.8),
      ],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  /// Generates a smooth, non-linearly eased [LinearGradient] between key colors.
  /// Uses cubic Hermite smoothstep (3t^2 - 2t^3) interpolation to eliminate visible
  /// linear color seams and harsh banding, giving organic fluid/glass transitions.
  static LinearGradient createNonLinearGradient({
    required AlignmentGeometry begin,
    required AlignmentGeometry end,
    required List<Color> colors,
    List<double>? stops,
    int intermediateSamplesPerSegment = 3,
  }) {
    if (colors.length < 2) {
      return LinearGradient(begin: begin, end: end, colors: colors, stops: stops);
    }

    final keyStops = stops ??
        List.generate(
          colors.length,
          (i) => i / (colors.length - 1),
        );

    assert(colors.length == keyStops.length);

    final resultColors = <Color>[];
    final resultStops = <double>[];

    for (int i = 0; i < colors.length - 1; i++) {
      final cStart = colors[i];
      final cEnd = colors[i + 1];
      final sStart = keyStops[i];
      final sEnd = keyStops[i + 1];

      // Add the start stop (only for the very first segment)
      if (i == 0) {
        resultColors.add(cStart);
        resultStops.add(sStart);
      }

      // Add intermediate smoothstep samples
      for (int step = 1; step <= intermediateSamplesPerSegment; step++) {
        final t = step / (intermediateSamplesPerSegment + 1);
        // Hermite smoothstep easing: S(t) = 3t^2 - 2t^3
        final easedT = t * t * (3 - 2 * t);

        final interpolatedColor = Color.lerp(cStart, cEnd, easedT) ?? cEnd;
        final interpolatedStop = sStart + (sEnd - sStart) * t;

        resultColors.add(interpolatedColor);
        resultStops.add(interpolatedStop);
      }

      resultColors.add(cEnd);
      resultStops.add(sEnd);
    }

    return LinearGradient(
      begin: begin,
      end: end,
      colors: resultColors,
      stops: resultStops,
    );
  }

  /// Selection overlay gradient for photos, active items, and tiles
  static LinearGradient selectionOverlayGradient({double opacity = 0.22}) {
    return createNonLinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        bubbleMagenta.withValues(alpha: opacity),
        bubbleBlue.withValues(alpha: opacity * 0.95),
        bubbleGreen.withValues(alpha: opacity),
      ],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  /// Base frosted glass gradient with subtle iridescent bubble reflection
  static LinearGradient glassGradient(
    BuildContext context, {
    double opacityMultiplier = 1.0,
    bool isCard = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      if (isCard) {
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B1822),
            Color(0xFF12141A),
          ],
        );
      }
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF1E1A26).withValues(alpha: (0.92 * opacityMultiplier).clamp(0.0, 1.0)),
          const Color(0xFF11141E).withValues(alpha: (0.84 * opacityMultiplier).clamp(0.0, 1.0)),
        ],
      );
    } else {
      if (isCard) {
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFF9FAFD),
          ],
        );
      }
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: (0.92 * opacityMultiplier).clamp(0.0, 1.0)),
          const Color(0xFFF6F8FC).withValues(alpha: (0.80 * opacityMultiplier).clamp(0.0, 1.0)),
        ],
      );
    }
  }

  /// Primary Liquid Glass gradient for active, primary, and selection elements.
  /// Uses Signature Bubble Blue with vertical tonal reflection.
  static LinearGradient primaryLiquidGradient({BuildContext? context}) {
    return bubbleBlueGradient;
  }

  /// Contrast text and icon color for elements styled with [primaryLiquidGradient]
  static Color primaryTextColor(BuildContext context) {
    return Colors.white;
  }


  /// Crisp specular border color with delicate glass reflection tint
  static Color specularBorderColor(BuildContext context, {double opacityMultiplier = 1.0}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withValues(alpha: (0.16 * opacityMultiplier).clamp(0.0, 1.0))
        : (opacityMultiplier > 1.2 ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0));
  }

  /// Crisp specular glass border
  static Border glassBorder(
    BuildContext context, {
    double width = 1.2,
    double opacityMultiplier = 1.0,
  }) {
    return Border.all(
      color: specularBorderColor(context, opacityMultiplier: opacityMultiplier),
      width: width,
    );
  }

  /// Floating ambient depth shadows for clean, elevated frosted glass surfaces
  static List<BoxShadow> glassShadows(
    BuildContext context, {
    bool elevate = true,
    double blur = 24,
    Offset offset = const Offset(0, 8),
  }) {
    if (!elevate) return const [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.08),
        blurRadius: blur,
        offset: offset,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: bubbleBlue.withValues(alpha: isDark ? 0.025 : 0.02),
        blurRadius: blur * 1.2,
        offset: const Offset(0, 2),
      ),
    ];
  }

  /// Fluid capsule pill background
  static Color pillBackground(BuildContext context, {bool isSelected = true}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isSelected) {
      return isDark
          ? Colors.white.withValues(alpha: 0.16)
          : const Color(0xFFE2E8F0);
    }
    return isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFF1F5F9);
  }

  /// Fluid capsule pill border color
  static Color pillBorderColor(BuildContext context, {bool isSelected = true}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isSelected) {
      return isDark
          ? Colors.white.withValues(alpha: 0.24)
          : const Color(0xFFCBD5E1);
    }
    return isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE2E8F0);
  }

  /// Primary text color based on brightness
  static Color textPrimary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white : const Color(0xFF0F172A);
  }

  /// Secondary text color based on brightness
  static Color textSecondary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFA1A1AA) : const Color(0xFF475569);
  }

  /// Neutral background for avatar placeholders and skeletons
  static Color avatarBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7);
  }

  /// Photo grid item placeholder and neutral container fill
  static Color gridBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF18181B) : const Color(0xFFF1F3F6);
  }

  /// Elevated card surface color
  static Color cardBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF18181B) : Colors.white;
  }

  /// Background color for nested containers, inner input fields, and comment boxes inside cards
  static Color nestedSurface(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF1E1E22) : const Color(0xFFF1F3F6);
  }

  /// Subtle border color for cards and dialogs
  static Color subtleBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFE2E8F0);
  }

  /// Subtle divider color
  static Color dividerColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE2E8F0);
  }
}

/// Custom painter that draws an authentic 3D soap-bubble texture:
/// 1. Crystal-clear ultra-transparent glass body
/// 2. Delicate iridescent thin-film rainbow sheen across the surface
/// 3. Top convex curved specular glint (3D bubble dome reflection)
/// 4. Bottom ambient ground bounce reflection
/// 5. Inner specular hairline ring
/// 6. Vibrant iridescent border rim
class BubblePillPainter extends CustomPainter {
  final Gradient? borderGradient;
  final Gradient? iridescentSheenGradient;
  final double strokeWidth;
  final double radius;
  final bool isDark;

  const BubblePillPainter({
    this.borderGradient,
    this.iridescentSheenGradient,
    this.strokeWidth = 1.3,
    required this.radius,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rect = Offset.zero & size;
    final innerRRect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth),
      Radius.circular((radius - strokeWidth).clamp(0.0, double.infinity)),
    );
    final borderRRect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular((radius - strokeWidth / 2).clamp(0.0, double.infinity)),
    );

    // 1. Base ultra-transparent glass fill
    final baseGlassPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.02),
              ]
            : [
                Colors.white.withValues(alpha: 0.16),
                Colors.white.withValues(alpha: 0.04),
              ],
      ).createShader(rect);
    canvas.drawRRect(innerRRect, baseGlassPaint);

    // 2. Iridescent thin-film prismatic sheen (Soap bubble texture across body)
    final effectiveSheen = iridescentSheenGradient ??
        LiquidGlassTheme.bubbleReflectionGradient(opacity: isDark ? 0.10 : 0.08);
    final sheenPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = effectiveSheen.createShader(rect);
    canvas.drawRRect(innerRRect, sheenPaint);

    // 3. Top convex specular glint (3D curved bubble dome reflection)
    final glintWidth = size.width * 0.74;
    final glintHeight = (size.height * 0.38).clamp(8.0, 22.0);
    final glintLeft = (size.width - glintWidth) / 2;
    final glintTop = strokeWidth + 1.2;
    final glintRect = Rect.fromLTWH(glintLeft, glintTop, glintWidth, glintHeight);
    final glintRRect = RRect.fromRectAndRadius(
      glintRect,
      Radius.circular(glintHeight / 2),
    );
    final glintPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.28 : 0.44),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(glintRect);
    canvas.drawRRect(glintRRect, glintPaint);

    // 4. Bottom ambient ground-bounce reflection
    final bounceWidth = size.width * 0.52;
    final bounceHeight = (size.height * 0.22).clamp(5.0, 14.0);
    final bounceLeft = (size.width - bounceWidth) / 2;
    final bounceTop = size.height - strokeWidth - bounceHeight - 1.2;
    final bounceRect = Rect.fromLTWH(bounceLeft, bounceTop, bounceWidth, bounceHeight);
    final bounceRRect = RRect.fromRectAndRadius(
      bounceRect,
      Radius.circular(bounceHeight / 2),
    );
    final bouncePaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          LiquidGlassTheme.bubbleBlue.withValues(alpha: isDark ? 0.12 : 0.08),
          LiquidGlassTheme.bubbleBlue.withValues(alpha: 0.0),
        ],
      ).createShader(bounceRect);
    canvas.drawRRect(bounceRRect, bouncePaint);

    // 5. Inner specular hairline ring
    final innerSpecularPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = Colors.white.withValues(alpha: isDark ? 0.14 : 0.35);
    canvas.drawRRect(innerRRect, innerSpecularPaint);

    // 6. Clean specular border rim (no chromatic gradient line)
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    if (borderGradient != null) {
      strokePaint.shader = borderGradient!.createShader(rect);
    } else {
      strokePaint.color = isDark
          ? Colors.white.withValues(alpha: 0.20)
          : const Color(0xFFCBD5E1);
    }
    canvas.drawRRect(borderRRect, strokePaint);
  }

  @override
  bool shouldRepaint(covariant BubblePillPainter oldDelegate) {
    return oldDelegate.borderGradient != borderGradient ||
        oldDelegate.iridescentSheenGradient != iridescentSheenGradient ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius ||
        oldDelegate.isDark != isDark;
  }
}

/// Floating translucent bubble pill with an iridescent gradient rim,
/// thin-film rainbow sheen texture, and 3D specular curved dome reflection.
class LiquidBubblePill extends StatelessWidget {
  final double radius;
  final double strokeWidth;
  final bool isDark;
  final Widget? child;

  const LiquidBubblePill({
    super.key,
    required this.radius,
    this.strokeWidth = 1.15,
    required this.isDark,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: LiquidGlassTheme.bubbleBlue.withValues(alpha: isDark ? 0.15 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 1),
          ),
          if (isDark)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.07),
              blurRadius: 7,
              offset: const Offset(0, -1),
            ),
        ],
      ),
      child: CustomPaint(
        painter: BubblePillPainter(
          iridescentSheenGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    LiquidGlassTheme.bubbleMagenta.withValues(alpha: 0.08),
                    LiquidGlassTheme.bubbleBlue.withValues(alpha: 0.10),
                    LiquidGlassTheme.bubbleGreen.withValues(alpha: 0.07),
                  ]
                : [
                    LiquidGlassTheme.bubbleMagenta.withValues(alpha: 0.06),
                    LiquidGlassTheme.bubbleBlue.withValues(alpha: 0.08),
                    LiquidGlassTheme.bubbleGreen.withValues(alpha: 0.05),
                  ],
            stops: const [0.0, 0.48, 1.0],
          ),
          strokeWidth: strokeWidth,
          radius: radius,
          isDark: isDark,
        ),
        child: child,
      ),
    );
  }
}

/// Telegram-style continuous screen-space gradient chat bubble with liquid glass glint.
/// Outgoing messages share a single vertical spectrum across the chat screen that shifts
/// continuously as the user scrolls.
class LiquidContinuousChatBubble extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final bool isSelected;
  final bool isDark;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final ScrollController? scrollController;
  final EdgeInsetsGeometry? padding;

  const LiquidContinuousChatBubble({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.isSelected = false,
    required this.isDark,
    this.border,
    this.boxShadow,
    this.scrollController,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveShadow = boxShadow ??
        [
          BoxShadow(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.30)
                : Colors.black.withValues(alpha: isDark ? 0.30 : 0.16),
            blurRadius: isSelected ? 12 : 8,
            offset: const Offset(0, 3),
          ),
        ];

    final effectiveBorder = border ??
        Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : (isDark
                  ? Colors.white.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.30)),
          width: isSelected ? 2.0 : 1.0,
        );

    final repaintListenable = scrollController ?? Scrollable.maybeOf(context)?.position;

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: effectiveShadow,
        border: effectiveBorder,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: CustomPaint(
          painter: _LiquidContinuousGradientPainter(
            context: context,
            borderRadius: borderRadius,
            isDark: isDark,
            repaint: repaintListenable,
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _LiquidContinuousGradientPainter extends CustomPainter {
  final BuildContext context;
  final BorderRadius borderRadius;
  final bool isDark;

  _LiquidContinuousGradientPainter({
    required this.context,
    required this.borderRadius,
    required this.isDark,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!context.mounted) return;
    final RenderObject? ro = context.findRenderObject();
    if (ro is! RenderBox || !ro.attached || !ro.hasSize) return;

    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final topPadding = mediaQuery.padding.top + kToolbarHeight;
    final bottomPadding = mediaQuery.padding.bottom + 70.0;
    final usableHeight = (screenSize.height - topPadding - bottomPadding).clamp(200.0, 3000.0);

    Offset globalPos = Offset.zero;
    try {
      globalPos = ro.localToGlobal(Offset.zero);
    } catch (_) {
      globalPos = Offset.zero;
    }

    final bubbleY = globalPos.dy.isFinite ? globalPos.dy : topPadding;

    // Viewport-mapped shader:
    // When bubble is at topPadding (near header), gradient top (magenta/violet) matches canvas y = 0.
    // When bubble is near bottom, gradient bottom (cyan/green) matches canvas.
    final screenGradientRect = Rect.fromLTWH(
      0,
      topPadding - bubbleY,
      size.width,
      usableHeight,
    );

    final gradient = LiquidGlassTheme.continuousChatGradient(isDark: isDark);
    final shader = gradient.createShader(screenGradientRect);

    final rrect = borderRadius.toRRect(Offset.zero & size);

    // 1. Base continuous liquid gradient
    final basePaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = shader;
    canvas.drawRRect(rrect, basePaint);

    // 2. Liquid glass soap-bubble specular dome glint
    final glintWidth = size.width * 0.85;
    final glintHeight = (size.height * 0.32).clamp(4.0, 14.0);
    final glintLeft = (size.width - glintWidth) / 2;
    const glintTop = 1.0;
    final glintRect = Rect.fromLTWH(glintLeft, glintTop, glintWidth, glintHeight);
    final glintRRect = RRect.fromRectAndRadius(glintRect, const Radius.circular(8.0));

    final glintPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.22 : 0.28),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(glintRect);
    canvas.drawRRect(glintRRect, glintPaint);
  }

  @override
  bool shouldRepaint(covariant _LiquidContinuousGradientPainter oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.borderRadius != borderRadius;
  }
}

/// A premium Liquid Glass icon that renders any [IconData] with the authentic
/// 3D soap-bubble aesthetic:
/// 1. Fluid multi-chromatic non-linear liquid bubble gradient (no harsh 2D linear stripes).
/// 2. Top-down 3D specular curved reflection glint layer (simulating curved glass dome reflection).
/// 3. Subtle ambient iridescent chromatic glow / drop shadow.
/// 4. Optional surrounding micro [LiquidBubblePill] glass badge if [withGlassPill] is true.
class BubbleGlassIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Gradient? gradient;
  final bool hasGlow;
  final bool withGlassPill;
  final Color? color;
  final VoidCallback? onTap;
  final String? tooltip;

  const BubbleGlassIcon({
    super.key,
    required this.icon,
    this.size = 20.0,
    this.gradient,
    this.hasGlow = true,
    this.withGlassPill = false,
    this.color,
    this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveGradient = gradient ??
        (color != null
            ? LinearGradient(colors: [color!, color!])
            : (isDark
                ? LiquidGlassTheme.bubbleIconGradient
                : LiquidGlassTheme.bubbleIconLightGradient));

    Widget iconGlyph = Stack(
      alignment: Alignment.center,
      children: [
        // 1. Ambient chromatic glow
        if (hasGlow)
          Transform.translate(
            offset: const Offset(0, 1),
            child: ShaderMask(
              shaderCallback: (bounds) => effectiveGradient.createShader(bounds),
              blendMode: BlendMode.srcIn,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: size * 0.18, sigmaY: size * 0.18),
                child: Opacity(
                  opacity: isDark ? 0.45 : 0.20,
                  child: Icon(icon, size: size, color: Colors.white),
                ),
              ),
            ),
          ),

        // 2. Base chromatic liquid glass body
        ShaderMask(
          shaderCallback: (bounds) => effectiveGradient.createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: Icon(icon, size: size, color: Colors.white),
        ),

        // 3. Top-down 3D specular curved reflection glint
        if (isDark)
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.65),
                Colors.white.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.58],
            ).createShader(bounds),
            blendMode: BlendMode.plus,
            child: Icon(icon, size: size, color: Colors.white),
          )
        else
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.35),
                Colors.white.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.50],
            ).createShader(bounds),
            blendMode: BlendMode.srcATop,
            child: Icon(icon, size: size, color: Colors.white),
          ),
      ],
    );

    if (withGlassPill) {
      final pillPadding = (size * 0.35).clamp(4.0, 10.0);
      Widget pill = Container(
        padding: EdgeInsets.all(pillPadding),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: LiquidGlassTheme.bubbleBlue.withValues(alpha: isDark ? 0.22 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: CustomPaint(
          painter: BubblePillPainter(
            radius: size,
            strokeWidth: 1.1,
            isDark: isDark,
          ),
          child: iconGlyph,
        ),
      );

      if (onTap != null) {
        pill = GestureDetector(
          onTap: () {
            SafeHaptics.selectionClick();
            onTap!();
          },
          behavior: HitTestBehavior.opaque,
          child: pill,
        );
      }
      return pill;
    }

    if (onTap != null) {
      iconGlyph = GestureDetector(
        onTap: () {
          SafeHaptics.selectionClick();
          onTap!();
        },
        behavior: HitTestBehavior.opaque,
        child: iconGlyph,
      );
    }

    if (tooltip != null && tooltip!.isNotEmpty) {
      iconGlyph = Tooltip(message: tooltip!, child: iconGlyph);
    }

    return SizedBox(
      width: size + 4,
      height: size + 4,
      child: Center(child: iconGlyph),
    );
  }
}

/// Frosted liquid glass container with backdrop blur, specular border, and ambient shadow.
class LiquidGlassContainer extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry borderRadius;
  final double blur;
  final BoxBorder? border;
  final Gradient? gradient;
  final List<BoxShadow>? shadows;
  final bool hasShadow;
  final bool hasBorder;
  final bool hasBlur;
  final VoidCallback? onTap;
  final ShapeBorder? customShape;

  const LiquidGlassContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.blur = 16.0,
    this.border,
    this.gradient,
    this.shadows,
    this.hasShadow = true,
    this.hasBorder = true,
    this.hasBlur = false,
    this.onTap,
    this.customShape,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveShadows = hasShadow
        ? (shadows ?? LiquidGlassTheme.glassShadows(context))
        : null;

    final effectiveGradient =
        gradient ?? LiquidGlassTheme.glassGradient(context);

    final effectiveBorder = hasBorder
        ? (border ?? LiquidGlassTheme.glassBorder(context))
        : null;

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        gradient: effectiveGradient,
        borderRadius: borderRadius as BorderRadius?,
        border: effectiveBorder,
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius as BorderRadius?,
          onTap: () {
            SafeHaptics.lightImpact();
            onTap!();
          },
          child: content,
        ),
      );
    }

    if (!hasBlur || blur <= 0) {
      return Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: borderRadius as BorderRadius?,
          boxShadow: effectiveShadows,
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: content,
        ),
      );
    }

    return RepaintBoundary(
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: borderRadius as BorderRadius?,
          boxShadow: effectiveShadows,
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Liquid Glass Card tailored for posts, profile cards, and feed items.
class LiquidGlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double blur;
  final bool hasBlur;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.padding,
    this.borderRadius = 24.0,
    this.onTap,
    this.onLongPress,
    this.blur = 12.0,
    this.hasBlur = false,
  });

  @override
  State<LiquidGlassCard> createState() => _LiquidGlassCardState();
}

class _LiquidGlassCardState extends State<LiquidGlassCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(widget.borderRadius);

    Widget cardBody = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        gradient: LiquidGlassTheme.glassGradient(context, isCard: true),
        borderRadius: r,
        border: LiquidGlassTheme.glassBorder(context),
      ),
      child: widget.child,
    );

    if (widget.onTap != null || widget.onLongPress != null) {
      cardBody = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: r,
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap != null
              ? () {
                  SafeHaptics.lightImpact();
                  widget.onTap!();
                }
              : null,
          onLongPress: widget.onLongPress != null
              ? () {
                  SafeHaptics.mediumImpact();
                  widget.onLongPress!();
                }
              : null,
          child: cardBody,
        ),
      );
    }

    final card = AnimatedScale(
      scale: _isPressed ? 0.982 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: widget.margin,
        decoration: BoxDecoration(
          borderRadius: r,
          boxShadow: LiquidGlassTheme.glassShadows(context),
        ),
        child: ClipRRect(
          borderRadius: r,
          child: (!widget.hasBlur || widget.blur <= 0)
              ? cardBody
              : BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
                  child: cardBody,
                ),
        ),
      ),
    );

    if (widget.hasBlur && widget.blur > 0) {
      return RepaintBoundary(child: card);
    }
    return card;
  }
}

/// Fluid Pill / Capsule button or chip matching the [AppNavBar] style.
class LiquidGlassPill extends StatelessWidget {
  final Widget? icon;
  final String? label;
  final Widget? customContent;
  final bool isSelected;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double height;
  final double? fontSize;
  final Color? activeColor;
  final Color? activeTextColor;

  const LiquidGlassPill({
    super.key,
    this.icon,
    this.label,
    this.customContent,
    this.isSelected = false,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    this.height = 36,
    this.fontSize,
    this.activeColor,
    this.activeTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textStyle = TextStyle(
      fontSize: fontSize ?? (height <= 32 ? 12.0 : 13.0),
      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      letterSpacing: 0.15,
      color: isSelected
          ? (activeTextColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)))
          : (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF475569)),
    );

    final bg = isSelected
        ? (activeColor ?? LiquidGlassTheme.pillBackground(context, isSelected: true))
        : LiquidGlassTheme.pillBackground(context, isSelected: false);

    final border = Border.all(
      color: LiquidGlassTheme.pillBorderColor(context, isSelected: isSelected),
      width: 1.1,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap != null
          ? () {
              SafeHaptics.lightImpact();
              onTap!();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(height / 2),
          border: border,
        ),
        child: customContent ??
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  icon!,
                  if (label != null) const SizedBox(width: 6),
                ],
                if (label != null)
                  Flexible(
                    child: Text(
                    label!,
                    style: textStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
      ),
    );
  }
}

/// Custom painter that renders an authentic 3D soap-bubble liquid glass button texture:
/// 1. Vibrant fluid chromatic body fill (using [gradient])
/// 2. Delicate iridescent thin-film rainbow sheen across surface
/// 3. Top convex curved specular dome reflection glint
/// 4. Bottom ambient ground-bounce reflection
/// 5. Inner specular hairline ring
/// 6. Crisp directional specular crystalline border rim
class LiquidGlassButtonPainter extends CustomPainter {
  final Gradient gradient;
  final double radius;
  final double strokeWidth;
  final bool isDark;

  const LiquidGlassButtonPainter({
    required this.gradient,
    required this.radius,
    this.strokeWidth = 1.2,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(radius),
    );
    final innerRRect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth),
      Radius.circular((radius - strokeWidth).clamp(0.0, double.infinity)),
    );

    final isCustom = gradient != LiquidGlassTheme.bubbleIconGradient &&
        gradient != LiquidGlassTheme.bubbleGradient &&
        gradient != LiquidGlassTheme.bubbleBlueGradient;

    // 1. Base vibrant fluid chromatic body
    final basePaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = gradient.createShader(rect);
    canvas.drawRRect(rrect, basePaint);

    // 2. Delicate iridescent thin-film sheen (soap-bubble micro texture)
    final sheenPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: const Alignment(-0.35, -2.0),
        end: const Alignment(0.35, 2.0),
        colors: isCustom
            ? [
                Colors.white.withValues(alpha: isDark ? 0.16 : 0.20),
                Colors.white.withValues(alpha: 0.04),
              ]
            : [
                Colors.white.withValues(alpha: isDark ? 0.10 : 0.14),
                const Color(0xFFE879F9).withValues(alpha: isDark ? 0.05 : 0.04),
                LiquidGlassTheme.bubbleBlue.withValues(alpha: isDark ? 0.05 : 0.04),
                const Color(0xFF10B981).withValues(alpha: isDark ? 0.04 : 0.03),
                Colors.white.withValues(alpha: isDark ? 0.05 : 0.08),
              ],
        stops: isCustom ? const [0.0, 1.0] : const [0.0, 0.15, 0.50, 0.85, 1.0],
      ).createShader(rect);
    canvas.drawRRect(innerRRect, sheenPaint);

    // 3. Top convex curved specular dome glint (3D bubble dome reflection)
    final glintWidth = size.width * 0.82;
    final glintHeight = (size.height * 0.36).clamp(5.0, 18.0);
    final glintLeft = (size.width - glintWidth) / 2;
    final glintTop = strokeWidth + 0.8;
    final glintRect = Rect.fromLTWH(glintLeft, glintTop, glintWidth, glintHeight);
    final glintRadius = (radius * 0.7).clamp(4.0, glintHeight / 2);
    final glintRRect = RRect.fromRectAndRadius(
      glintRect,
      Radius.circular(glintRadius),
    );

    final glintPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.32 : 0.42),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(glintRect);
    canvas.drawRRect(glintRRect, glintPaint);

    // 4. Bottom ambient ground-bounce reflection
    final bounceWidth = size.width * 0.60;
    final bounceHeight = (size.height * 0.20).clamp(3.0, 10.0);
    final bounceLeft = (size.width - bounceWidth) / 2;
    final bounceTop = size.height - strokeWidth - bounceHeight - 0.8;
    final bounceRect = Rect.fromLTWH(bounceLeft, bounceTop, bounceWidth, bounceHeight);
    final bounceRadius = (radius * 0.5).clamp(3.0, bounceHeight / 2);
    final bounceRRect = RRect.fromRectAndRadius(
      bounceRect,
      Radius.circular(bounceRadius),
    );

    final bouncePaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: isCustom
            ? [
                Colors.white.withValues(alpha: isDark ? 0.12 : 0.08),
                Colors.white.withValues(alpha: 0.0),
              ]
            : [
                LiquidGlassTheme.bubbleBlue.withValues(alpha: isDark ? 0.12 : 0.08),
                Colors.white.withValues(alpha: 0.0),
              ],
        stops: const [0.0, 1.0],
      ).createShader(bounceRect);
    canvas.drawRRect(bounceRRect, bouncePaint);

    // 5. Inner specular hairline ring
    final innerHairlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = Colors.white.withValues(alpha: isDark ? 0.20 : 0.32);
    canvas.drawRRect(innerRRect, innerHairlinePaint);

    // 6. Crisp directional specular crystalline border rim
    final borderRRect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular((radius - strokeWidth / 2).clamp(0.0, double.infinity)),
    );
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = LinearGradient(
        begin: const Alignment(-0.35, -2.0),
        end: const Alignment(0.35, 2.0),
        colors: isCustom
            ? [
                Colors.white.withValues(alpha: isDark ? 0.65 : 0.80),
                Colors.white.withValues(alpha: 0.20),
              ]
            : (isDark
                ? [
                    Colors.white.withValues(alpha: 0.60),
                    const Color(0xFFE879F9).withValues(alpha: 0.15),
                    LiquidGlassTheme.bubbleBlue.withValues(alpha: 0.20),
                    const Color(0xFF10B981).withValues(alpha: 0.16),
                    Colors.white.withValues(alpha: 0.12),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.72),
                    const Color(0xFFE879F9).withValues(alpha: 0.12),
                    LiquidGlassTheme.bubbleBlue.withValues(alpha: 0.18),
                    const Color(0xFF10B981).withValues(alpha: 0.14),
                    Colors.white.withValues(alpha: 0.14),
                  ]),
        stops: isCustom ? const [0.0, 1.0] : const [0.0, 0.15, 0.50, 0.85, 1.0],
      ).createShader(rect);
    canvas.drawRRect(borderRRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant LiquidGlassButtonPainter oldDelegate) {
    return oldDelegate.gradient != gradient ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.isDark != isDark;
  }
}

/// Liquid Glass Interactive Button (Pill shaped with frosted glass or vibrant gradient).
class LiquidGlassButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget? icon;
  final String label;
  final bool isPrimary;
  final bool isBrandGradient;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool isLoading;
  final bool hasBlur;
  final Gradient? customGradient;
  final Color? customBackgroundColor;
  final Color? customTextColor;

  const LiquidGlassButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isPrimary = true,
    this.isBrandGradient = false,
    this.height,
    this.padding,
    this.borderRadius = 22,
    this.isLoading = false,
    this.hasBlur = false,
    this.customGradient,
    this.customBackgroundColor,
    this.customTextColor,
  });

  @override
  State<LiquidGlassButton> createState() => _LiquidGlassButtonState();
}

class _LiquidGlassButtonState extends State<LiquidGlassButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final effectiveHeight = widget.height ?? 44.0;
    final effectivePadding = widget.padding ??
        EdgeInsets.symmetric(
          horizontal: effectiveHeight <= 38 ? 12 : 16,
        );

    final primaryTextColor = widget.customTextColor ?? LiquidGlassTheme.primaryTextColor(context);

    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: widget.isPrimary ? primaryTextColor : (widget.customTextColor ?? (isDark ? Colors.white : Colors.black87)),
            ),
          )
        else ...[
          if (widget.icon != null) ...[
            widget.icon!,
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(
                fontSize: effectiveHeight <= 36 ? 13 : 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
                color: widget.isPrimary
                    ? primaryTextColor
                    : (widget.customTextColor ?? (isDark ? Colors.white : const Color(0xFF111827))),
              ),
            ),
          ),
        ],
      ],
    );

    final r = BorderRadius.circular(widget.borderRadius);

    if (widget.isPrimary) {
      final effectiveGradient = widget.customGradient ??
          (widget.isBrandGradient
              ? LiquidGlassTheme.primaryLiquidGradient(context: context)
              : LiquidGlassTheme.bubbleBlueGradient);
      final shadowColor = widget.customBackgroundColor ??
          (widget.customGradient != null ? const Color(0xFFE53935) : LiquidGlassTheme.bubbleBlue);

      return AnimatedScale(
        scale: _isPressed ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: Container(
          height: effectiveHeight,
          decoration: BoxDecoration(
            borderRadius: r,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.07),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: shadowColor.withValues(alpha: isDark ? 0.08 : 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CustomPaint(
            painter: LiquidGlassButtonPainter(
              gradient: effectiveGradient,
              radius: widget.borderRadius,
              isDark: isDark,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: r,
                onTapDown: (_) => setState(() => _isPressed = true),
                onTapUp: (_) => setState(() => _isPressed = false),
                onTapCancel: () => setState(() => _isPressed = false),
                onTap: widget.onPressed != null && !widget.isLoading
                    ? () {
                        SafeHaptics.lightImpact();
                        widget.onPressed!();
                      }
                    : null,
                child: Padding(
                  padding: effectivePadding,
                  child: Center(child: buttonContent),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Frosted Glass Button (Secondary)
    final buttonBody = Container(
      decoration: BoxDecoration(
        gradient: LiquidGlassTheme.glassGradient(context),
        borderRadius: r,
        border: LiquidGlassTheme.glassBorder(context),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: r,
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onPressed != null && !widget.isLoading
              ? () {
                  SafeHaptics.lightImpact();
                  widget.onPressed!();
                }
              : null,
          child: Padding(
            padding: effectivePadding,
            child: Center(child: buttonContent),
          ),
        ),
      ),
    );

    final elevatedContainer = Container(
      height: effectiveHeight,
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: LiquidGlassTheme.glassShadows(context, blur: 8),
      ),
      child: ClipRRect(
        borderRadius: r,
        child: widget.hasBlur
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: buttonBody,
              )
            : buttonBody,
      ),
    );

    return AnimatedScale(
      scale: _isPressed ? 0.975 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOutCubic,
      child: elevatedContainer,
    );
  }
}

/// Circular 3D liquid soap-bubble glass action button (used for sending comments, replies, messages, etc.)
class LiquidGlassIconButton extends StatefulWidget {
  final IconData? icon;
  final Widget? child;
  final VoidCallback? onPressed;
  final double size;
  final bool isPrimary;
  final bool isLoading;
  final Gradient? gradient;
  final Color? color;
  final Color? iconColor;
  final String? tooltip;

  const LiquidGlassIconButton({
    super.key,
    this.icon,
    this.child,
    required this.onPressed,
    this.size = 38.0,
    this.isPrimary = true,
    this.isLoading = false,
    this.gradient,
    this.color,
    this.iconColor,
    this.tooltip,
  }) : assert(icon != null || child != null);

  @override
  State<LiquidGlassIconButton> createState() => _LiquidGlassIconButtonState();
}

class _LiquidGlassIconButtonState extends State<LiquidGlassIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveGradient = widget.gradient ??
        (widget.isPrimary
            ? LiquidGlassTheme.bubbleBlueGradient
            : LiquidGlassTheme.glassGradient(context));
    final effectiveIconColor = widget.iconColor ?? (widget.isPrimary ? Colors.white : LiquidGlassTheme.textPrimary(context));

    Widget content;
    if (widget.isLoading) {
      content = SizedBox(
        width: widget.size * 0.45,
        height: widget.size * 0.45,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: effectiveIconColor,
        ),
      );
    } else if (widget.child != null) {
      content = widget.child!;
    } else {
      content = Icon(
        widget.icon,
        size: widget.size * 0.46,
        color: effectiveIconColor,
      );
    }

    Widget button;
    if (widget.isPrimary) {
      final shadowColor = widget.color ?? (widget.gradient != null ? const Color(0xFFE53935) : LiquidGlassTheme.bubbleBlue);
      button = Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.07),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: shadowColor.withValues(alpha: isDark ? 0.08 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: CustomPaint(
          painter: LiquidGlassButtonPainter(
            gradient: effectiveGradient,
            radius: widget.size / 2,
            isDark: isDark,
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              onTap: widget.onPressed != null && !widget.isLoading
                  ? () {
                      SafeHaptics.lightImpact();
                      widget.onPressed!();
                    }
                  : null,
              child: Center(child: content),
            ),
          ),
        ),
      );
    } else {
      button = Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LiquidGlassTheme.glassGradient(context),
          border: LiquidGlassTheme.glassBorder(context),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: widget.onPressed != null && !widget.isLoading
                ? () {
                    SafeHaptics.lightImpact();
                    widget.onPressed!();
                  }
                : null,
            child: Center(child: content),
          ),
        ),
      );
    }

    button = AnimatedScale(
      scale: _isPressed ? 0.94 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOutCubic,
      child: button,
    );

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }

    return button;
  }
}

/// Standardized Liquid Glass Back Button with tactile haptics,
/// consistent 22pt Lucide chevron, and unified pop logic across all navigators.
class BubbleBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;
  final double size;

  const BubbleBackButton({
    super.key,
    this.onPressed,
    this.color,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        LucideIcons.chevronLeft,
        size: size,
        color: color ?? LiquidGlassTheme.textPrimary(context),
      ),
      onPressed: () {
        SafeHaptics.lightImpact();
        if (onPressed != null) {
          onPressed!();
          return;
        }
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else if (context.canPop()) {
          context.pop();
        } else if (rootNavigatorKey.currentState?.canPop() ?? false) {
          rootNavigatorKey.currentState?.pop();
        }
      },
    );
  }
}

/// Liquid Glass App Bar with backdrop blur, frosted gradient, and bottom specular rim.
class LiquidGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final double elevation;
  final bool automaticallyImplyLeading;

  const LiquidGlassAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.bottom,
    this.centerTitle = true,
    this.elevation = 0,
    this.automaticallyImplyLeading = true,
  });

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0.0;
    return Size.fromHeight(kToolbarHeight + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.paddingOf(context).top;

    final canGoBack = automaticallyImplyLeading &&
        (Navigator.of(context).canPop() ||
            context.canPop() ||
            (rootNavigatorKey.currentState?.canPop() ?? false));

    final Widget? leadingWidget = leading ??
        (canGoBack
            ? const BubbleBackButton()
            : null);

    final Widget? titleWidget = title != null
        ? DefaultTextStyle(
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: LiquidGlassTheme.textPrimary(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            child: title!,
          )
        : null;

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                gradient: LiquidGlassTheme.glassGradient(context, opacityMultiplier: 0.95),
              ),
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: topPadding),
                      SizedBox(
                        height: kToolbarHeight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (leadingWidget != null)
                                leadingWidget
                              else
                                const SizedBox(width: 8),
                              if (titleWidget != null)
                                Expanded(
                                  child: Align(
                                    alignment: centerTitle ? Alignment.center : Alignment.centerLeft,
                                    child: titleWidget,
                                  ),
                                )
                              else
                                const Spacer(),
                              if (actions != null && actions!.isNotEmpty)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: actions!,
                                )
                              else if (centerTitle && leadingWidget != null)
                                const SizedBox(width: 48)
                              else
                                const SizedBox(width: 8),
                            ],
                          ),
                        ),
                      ),
                      if (bottom != null)
                        SizedBox(
                          height: bottom!.preferredSize.height,
                          child: bottom!,
                        ),
                    ],
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 1.0,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : const Color(0xFFE2E8F0),
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
}

/// Liquid Glass Search Field Pill with backdrop blur and fluid styling.
class LiquidGlassSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final String hintText;
  final Widget? trailing;
  final double height;
  final FocusNode? focusNode;

  const LiquidGlassSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onClear,
    this.hintText = 'Search...',
    this.trailing,
    this.height = 38,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.search,
            size: 18,
            color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF475569),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              style: TextStyle(
                fontSize: 14,
                color: LiquidGlassTheme.textPrimary(context),
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF71717A) : const Color(0xFF64748B),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          if (controller?.text.isNotEmpty ?? false)
            GestureDetector(
              onTap: () {
                controller?.clear();
                onClear?.call();
              },
              child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: Icon(
                  LucideIcons.xCircle,
                  size: 16,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
            ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Item definition for fluid liquid glass bottom sheet option selector.
class LiquidGlassOptionItem<T> {
  final T value;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;

  const LiquidGlassOptionItem({
    required this.value,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
  });
}

/// Displays an animated Liquid Glass dialog with fluid scale-morph transition,
/// tactile haptics, and frosted dark backdrop.
Future<T?> showBubbleDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  SafeHaptics.lightImpact();
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (ctx, anim1, anim2) => builder(ctx),
    transitionBuilder: (ctx, anim, secAnim, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return ScaleTransition(
        scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
        child: FadeTransition(
          opacity: curved,
          child: child,
        ),
      );
    },
  );
}

/// Displays a stylized confirmation dialog reusing Liquid Glass tokens.
Future<bool?> showBubbleConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
}) {
  return showBubbleDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: LiquidGlassTheme.cardBackground(ctx),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: LiquidGlassTheme.subtleBorder(ctx),
            width: 1.2,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: LiquidGlassTheme.textPrimary(ctx),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: LiquidGlassTheme.textSecondary(ctx),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              cancelLabel,
              style: TextStyle(color: LiquidGlassTheme.textSecondary(ctx)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive
                  ? const Color(0xFFEF4444)
                  : LiquidGlassTheme.bubbleBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
}

/// Displays an animated Liquid Glass bottom sheet with fluid spring entrance,
/// tactile haptics, and frosted dark backdrop barrier.
Future<T?> showBubbleModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool enableDrag = true,
  Color? barrierColor,
  ShapeBorder? shape,
  double? elevation,
}) {
  SafeHaptics.lightImpact();
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    elevation: elevation ?? 0,
    backgroundColor: Colors.transparent,
    barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.50),
    shape: shape,
    sheetAnimationStyle: AnimationStyle(
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ),
    builder: builder,
  );
}

/// Displays an ultra-fluid liquid glass bottom sheet options picker with specular border and haptics.
Future<T?> showLiquidGlassOptionSheet<T>({
  required BuildContext context,
  required String title,
  String? subtitle,
  required List<LiquidGlassOptionItem<T>> options,
  required T selectedValue,
}) {
  return showBubbleModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return LiquidGlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: LiquidGlassTheme.textPrimary(ctx),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: LiquidGlassTheme.textSecondary(ctx),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: options.map((opt) {
                      final isSelected = opt.value == selectedValue;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            SafeHaptics.lightImpact();
                            Navigator.of(ctx).pop(opt.value);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : Colors.black.withValues(alpha: 0.06))
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.03)
                                      : Colors.black.withValues(alpha: 0.02)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? LiquidGlassTheme.specularBorderColor(ctx, opacityMultiplier: 1.5)
                                    : LiquidGlassTheme.specularBorderColor(ctx, opacityMultiplier: 0.4),
                                width: isSelected ? 1.4 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                if (opt.icon != null) ...[
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: (opt.iconColor ??
                                              (isSelected
                                                  ? LiquidGlassTheme.bubbleBlue
                                                  : (isDark ? Colors.white70 : Colors.black87)))
                                          .withValues(alpha: isDark ? 0.18 : 0.10),
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: Icon(
                                      opt.icon,
                                      color: opt.iconColor ??
                                          (isSelected
                                              ? LiquidGlassTheme.bubbleBlue
                                              : (isDark ? Colors.white70 : Colors.black87)),
                                      size: 19,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                ],
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        opt.title,
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                          fontSize: 15,
                                          color: LiquidGlassTheme.textPrimary(ctx),
                                        ),
                                      ),
                                      if (opt.subtitle != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          opt.subtitle!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: LiquidGlassTheme.textSecondary(ctx),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Icon(
                                  isSelected ? PhosphorIconsFill.checkCircle : PhosphorIconsRegular.circle,
                                  color: isSelected
                                      ? LiquidGlassTheme.bubbleBlue
                                      : (isDark ? Colors.white24 : Colors.black26),
                                  size: 21,
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
        ),
      );
    },
  );
}
