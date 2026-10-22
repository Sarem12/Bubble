import 'dart:math' as math;
import 'package:flutter/material.dart';

// ============================================================================
// 1. ORIGINAL BUBBLE ORB (:bubble:)
// ============================================================================

class BubbleOrbWidget extends StatefulWidget {
  final double size;
  final bool animate;

  const BubbleOrbWidget({super.key, required this.size, this.animate = true});

  @override
  State<BubbleOrbWidget> createState() => _BubbleOrbWidgetState();
}

class _BubbleOrbWidgetState extends State<BubbleOrbWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(BubbleOrbWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
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
      animation: _controller,
      builder: (context, child) {
        final progress = widget.animate ? _controller.value : 0.0;
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _BubbleOrbPainter(progress: progress),
        );
      },
    );
  }
}

class _BubbleOrbPainter extends CustomPainter {
  final double progress;

  _BubbleOrbPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.44;

    // Floating bob & subtle breathing
    final floatY = math.sin(progress * 2 * math.pi) * (size.height * 0.04);
    final squash = 1.0 + 0.03 * math.cos(progress * 2 * math.pi);
    final stretch = 1.0 - 0.03 * math.cos(progress * 2 * math.pi);

    canvas.save();
    canvas.translate(center.dx, center.dy + floatY);
    canvas.scale(squash, stretch);

    // Main Bubble Sphere gradient (Iridescent cyan -> royal blue -> vibrant violet)
    final sphereRect = Rect.fromCircle(center: Offset.zero, radius: radius);
    final baseGradient = RadialGradient(
      center: const Alignment(-0.25, -0.3),
      radius: 0.95,
      colors: const [
        Color(0xFFE0F7FA), // Soft cyan highlight center
        Color(0xFF4DD0E1), // Bright cyan
        Color(0xFF00B0FF), // Electric sky blue
        Color(0xFF2979FF), // Deep royal blue
        Color(0xFF7C4DFF), // Violet rim
        Color(0xFF651FFF), // Outer deep purple edge
      ],
      stops: const [0.0, 0.25, 0.5, 0.72, 0.9, 1.0],
    );

    final spherePaint = Paint()
      ..shader = baseGradient.createShader(sphereRect)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, radius, spherePaint);

    // Outer Glow / Rim light
    final rimPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.4, 0.5),
        radius: 0.85,
        colors: [
          Colors.transparent,
          const Color(0xFF00E5FF).withValues(alpha: 0.5),
          const Color(0xFFD500F9).withValues(alpha: 0.7),
        ],
        stops: const [0.7, 0.9, 1.0],
      ).createShader(sphereRect)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, radius, rimPaint);

    // Primary Specular Reflection (Top-left curved crescent shine)
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    final highlightRect = Rect.fromCenter(
      center: Offset(-radius * 0.38, -radius * 0.38),
      width: radius * 0.55,
      height: radius * 0.32,
    );
    canvas.save();
    canvas.rotate(-math.pi / 4);
    canvas.drawOval(highlightRect, highlightPaint);
    canvas.restore();

    // Secondary tiny pin-point sparkle
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(-radius * 0.55, -radius * 0.2),
      radius * 0.08,
      dotPaint,
    );

    // Bottom-right rim counter-reflection
    final bottomRimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    final bottomRect = Rect.fromCenter(
      center: Offset(radius * 0.35, radius * 0.38),
      width: radius * 0.45,
      height: radius * 0.16,
    );
    canvas.save();
    canvas.rotate(-math.pi / 4);
    canvas.drawOval(bottomRect, bottomRimPaint);
    canvas.restore();

    // Tiny orbiting mini-bubble
    final orbitAngle = progress * 2 * math.pi;
    final orbitX = math.cos(orbitAngle) * (radius * 0.95);
    final orbitY = math.sin(orbitAngle) * (radius * 0.95);
    final miniBubblePaint = Paint()
      ..color = const Color(0xFF80D8FF).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(orbitX, orbitY), radius * 0.12, miniBubblePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_BubbleOrbPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ============================================================================
// 2. BUBBLE PARTY / FIESTA (:bubble_party:)
// ============================================================================

class BubblePartyWidget extends StatefulWidget {
  final double size;
  final bool animate;

  const BubblePartyWidget({super.key, required this.size, this.animate = true});

  @override
  State<BubblePartyWidget> createState() => _BubblePartyWidgetState();
}

class _BubblePartyWidgetState extends State<BubblePartyWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(BubblePartyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
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
      animation: _controller,
      builder: (context, child) {
        final progress = widget.animate ? _controller.value : 0.0;
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _BubblePartyPainter(progress: progress),
        );
      },
    );
  }
}

class _BubblePartyPainter extends CustomPainter {
  final double progress;

  _BubblePartyPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;

    // Pulse scale
    final pulse = 1.0 + 0.06 * math.sin(progress * 4 * math.pi);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(pulse);

    // Festive rainbow sphere
    final sphereRect = Rect.fromCircle(center: Offset.zero, radius: radius);
    final partyGradient = RadialGradient(
      center: const Alignment(-0.2, -0.3),
      radius: 0.95,
      colors: const [
        Color(0xFFFFF9C4), // Golden yellow
        Color(0xFFFF80AB), // Vibrant pink
        Color(0xFF7C4DFF), // Purple
        Color(0xFF00E5FF), // Cyan
      ],
    );

    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()..shader = partyGradient.createShader(sphereRect),
    );

    // Specular shine
    canvas.drawCircle(
      Offset(-radius * 0.35, -radius * 0.35),
      radius * 0.22,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );

    // Confetti particles around
    final colors = [
      Colors.amber,
      Colors.pinkAccent,
      Colors.cyanAccent,
      Colors.lightGreenAccent,
      Colors.deepOrangeAccent,
    ];

    for (int i = 0; i < 7; i++) {
      final angle = (i * (2 * math.pi / 7)) + (progress * 2 * math.pi);
      final dist = radius * (1.15 + 0.15 * math.sin(progress * 2 * math.pi + i));
      final pX = math.cos(angle) * dist;
      final pY = math.sin(angle) * dist;
      final pColor = colors[i % colors.length];

      final confettiPaint = Paint()..color = pColor;
      if (i % 2 == 0) {
        // Star sparkle
        canvas.drawCircle(Offset(pX, pY), radius * 0.09, confettiPaint);
      } else {
        // Confetti flake
        canvas.drawRect(
          Rect.fromCenter(center: Offset(pX, pY), width: radius * 0.14, height: radius * 0.08),
          confettiPaint,
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_BubblePartyPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ============================================================================
// 3. BUBBLE FIRE (:bubble_fire:)
// ============================================================================

class BubbleFireWidget extends StatefulWidget {
  final double size;
  final bool animate;

  const BubbleFireWidget({super.key, required this.size, this.animate = true});

  @override
  State<BubbleFireWidget> createState() => _BubbleFireWidgetState();
}

class _BubbleFireWidgetState extends State<BubbleFireWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(BubbleFireWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
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
      animation: _controller,
      builder: (context, child) {
        final progress = widget.animate ? _controller.value : 0.0;
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _BubbleFirePainter(progress: progress),
        );
      },
    );
  }
}

class _BubbleFirePainter extends CustomPainter {
  final double progress;

  _BubbleFirePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    // Warm ambient glowing sphere
    final sphereRect = Rect.fromCircle(center: Offset.zero, radius: radius);
    final fireGradient = RadialGradient(
      center: const Alignment(0.0, 0.2),
      radius: 0.9,
      colors: const [
        Color(0xFFFFEB3B), // Yellow core
        Color(0xFFFF6D00), // Bright Orange
        Color(0xFFD50000), // Crimson Red
        Color(0xFF3E2723), // Dark outer edge
      ],
      stops: const [0.0, 0.4, 0.75, 1.0],
    );

    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()..shader = fireGradient.createShader(sphereRect),
    );

    // Inner lively flame tongue
    final flicker = math.sin(progress * 6 * math.pi) * (radius * 0.08);
    final flamePath = Path();
    flamePath.moveTo(0, radius * 0.5);
    flamePath.cubicTo(
      -radius * 0.55, radius * 0.2,
      -radius * 0.4, -radius * 0.4,
      0, -radius * 0.7 + flicker,
    );
    flamePath.cubicTo(
      radius * 0.4, -radius * 0.4,
      radius * 0.55, radius * 0.2,
      0, radius * 0.5,
    );
    flamePath.close();

    final innerFlamePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Color(0xFFFFD600), Color(0xFFFF3D00)],
      ).createShader(sphereRect);
    canvas.drawPath(flamePath, innerFlamePaint);

    // Core white flame hot spot
    final corePath = Path();
    corePath.moveTo(0, radius * 0.4);
    corePath.cubicTo(-radius * 0.25, radius * 0.2, -radius * 0.2, -radius * 0.1, 0, -radius * 0.35 + flicker);
    corePath.cubicTo(radius * 0.2, -radius * 0.1, radius * 0.25, radius * 0.2, 0, radius * 0.4);
    corePath.close();
    canvas.drawPath(corePath, Paint()..color = const Color(0xFFFFFDE7).withValues(alpha: 0.9));

    // Outer glass shine
    canvas.drawCircle(
      Offset(-radius * 0.35, -radius * 0.35),
      radius * 0.18,
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_BubbleFirePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ============================================================================
// 4. BUBBLE LOVE (:bubble_love:)
// ============================================================================

class BubbleLoveWidget extends StatefulWidget {
  final double size;
  final bool animate;

  const BubbleLoveWidget({super.key, required this.size, this.animate = true});

  @override
  State<BubbleLoveWidget> createState() => _BubbleLoveWidgetState();
}

class _BubbleLoveWidgetState extends State<BubbleLoveWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(BubbleLoveWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
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
      animation: _controller,
      builder: (context, child) {
        final progress = widget.animate ? _controller.value : 0.0;
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _BubbleLovePainter(progress: progress),
        );
      },
    );
  }
}

class _BubbleLovePainter extends CustomPainter {
  final double progress;

  _BubbleLovePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    // Heartbeat double thump: 0.0 -> 0.15 (pump 1), 0.25 -> 0.4 (pump 2), relax rest
    double beatScale = 1.0;
    if (progress < 0.15) {
      beatScale = 1.0 + 0.18 * math.sin(progress / 0.15 * math.pi);
    } else if (progress >= 0.2 && progress < 0.38) {
      beatScale = 1.0 + 0.12 * math.sin((progress - 0.2) / 0.18 * math.pi);
    }

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(beatScale);

    // Pink pearl translucent sphere
    final sphereRect = Rect.fromCircle(center: Offset.zero, radius: radius);
    final loveGradient = RadialGradient(
      center: const Alignment(-0.25, -0.25),
      radius: 0.95,
      colors: const [
        Color(0xFFFFCDD2), // Soft pink center
        Color(0xFFF06292), // Radiant rose
        Color(0xFFE91E63), // Vibrant pink
        Color(0xFFC2185B), // Deep berry
      ],
      stops: const [0.0, 0.4, 0.75, 1.0],
    );

    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()..shader = loveGradient.createShader(sphereRect),
    );

    // Inner Glowing Ruby Heart
    final heartPath = Path();
    final hSize = radius * 0.58;
    heartPath.moveTo(0, hSize * 0.7);
    heartPath.cubicTo(
      -hSize * 1.2, -hSize * 0.1,
      -hSize * 0.8, -hSize * 0.9,
      0, -hSize * 0.35,
    );
    heartPath.cubicTo(
      hSize * 0.8, -hSize * 0.9,
      hSize * 1.2, -hSize * 0.1,
      0, hSize * 0.7,
    );
    heartPath.close();

    final heartPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, -0.3),
        colors: [Color(0xFFFF80AB), Color(0xFFFF1744)],
      ).createShader(sphereRect)
      ..style = PaintingStyle.fill;
    canvas.drawPath(heartPath, heartPaint);

    // Specular shine
    canvas.drawCircle(
      Offset(-radius * 0.38, -radius * 0.38),
      radius * 0.18,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_BubbleLovePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ============================================================================
// 5. BUBBLE STELLAR / STAR (:bubble_star:)
// ============================================================================

class BubbleStarWidget extends StatefulWidget {
  final double size;
  final bool animate;

  const BubbleStarWidget({super.key, required this.size, this.animate = true});

  @override
  State<BubbleStarWidget> createState() => _BubbleStarWidgetState();
}

class _BubbleStarWidgetState extends State<BubbleStarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(BubbleStarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
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
      animation: _controller,
      builder: (context, child) {
        final progress = widget.animate ? _controller.value : 0.0;
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _BubbleStarPainter(progress: progress),
        );
      },
    );
  }
}

class _BubbleStarPainter extends CustomPainter {
  final double progress;

  _BubbleStarPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    // Cosmic indigo sphere
    final sphereRect = Rect.fromCircle(center: Offset.zero, radius: radius);
    final starGradient = RadialGradient(
      center: const Alignment(-0.2, -0.3),
      radius: 0.95,
      colors: const [
        Color(0xFF8C9EFF),
        Color(0xFF3D5AFE),
        Color(0xFF1A237E),
        Color(0xFF0D47A1),
      ],
    );

    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()..shader = starGradient.createShader(sphereRect),
    );

    // 4-Point Golden Star with slow rotation
    canvas.save();
    final rotation = progress * 2 * math.pi;
    canvas.rotate(rotation);

    final starPath = Path();
    final starRadius = radius * 0.58;
    final innerR = starRadius * 0.24;

    for (int i = 0; i < 8; i++) {
      final r = (i % 2 == 0) ? starRadius : innerR;
      final angle = i * math.pi / 4;
      final x = math.cos(angle) * r;
      final y = math.sin(angle) * r;
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }
    starPath.close();

    final starPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Colors.white, Color(0xFFFFD700), Color(0xFFFF6F00)],
      ).createShader(sphereRect);
    canvas.drawPath(starPath, starPaint);
    canvas.restore();

    // Specular shine
    canvas.drawCircle(
      Offset(-radius * 0.35, -radius * 0.35),
      radius * 0.16,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_BubbleStarPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ============================================================================
// 6. BUBBLE COOL (:bubble_cool:)
// ============================================================================

class BubbleCoolWidget extends StatefulWidget {
  final double size;
  final bool animate;

  const BubbleCoolWidget({super.key, required this.size, this.animate = true});

  @override
  State<BubbleCoolWidget> createState() => _BubbleCoolWidgetState();
}

class _BubbleCoolWidgetState extends State<BubbleCoolWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(BubbleCoolWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
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
      animation: _controller,
      builder: (context, child) {
        final progress = widget.animate ? _controller.value : 0.0;
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _BubbleCoolPainter(progress: progress),
        );
      },
    );
  }
}

class _BubbleCoolPainter extends CustomPainter {
  final double progress;

  _BubbleCoolPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    // Head tilt wobble
    final tilt = math.sin(progress * 2 * math.pi) * 0.08;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(tilt);

    // Blue glossy bubble
    final sphereRect = Rect.fromCircle(center: Offset.zero, radius: radius);
    final coolGradient = RadialGradient(
      center: const Alignment(-0.25, -0.3),
      radius: 0.95,
      colors: const [
        Color(0xFF80D8FF),
        Color(0xFF00B0FF),
        Color(0xFF0288D1),
      ],
    );
    canvas.drawCircle(Offset.zero, radius, Paint()..shader = coolGradient.createShader(sphereRect));

    // Sunglasses!
    final shadesPaint = Paint()..color = const Color(0xFF212121)..style = PaintingStyle.fill;
    final leftLens = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(-radius * 0.35, -radius * 0.05), width: radius * 0.52, height: radius * 0.38),
      const Radius.circular(6),
    );
    final rightLens = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(radius * 0.35, -radius * 0.05), width: radius * 0.52, height: radius * 0.38),
      const Radius.circular(6),
    );
    canvas.drawRRect(leftLens, shadesPaint);
    canvas.drawRRect(rightLens, shadesPaint);

    // Bridge between lenses
    canvas.drawRect(
      Rect.fromCenter(center: Offset(0, -radius * 0.08), width: radius * 0.22, height: radius * 0.08),
      shadesPaint,
    );

    // White glare reflection on glasses
    final glarePaint = Paint()..color = Colors.white.withValues(alpha: 0.65)..strokeWidth = 2..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(-radius * 0.48, -radius * 0.16), Offset(-radius * 0.25, 0.05), glarePaint);
    canvas.drawLine(Offset(radius * 0.22, -radius * 0.16), Offset(radius * 0.45, 0.05), glarePaint);

    // Smirk smile
    final smilePaint = Paint()..color = const Color(0xFF01579B)..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round;
    final smilePath = Path();
    smilePath.moveTo(-radius * 0.15, radius * 0.35);
    smilePath.quadraticBezierTo(radius * 0.1, radius * 0.5, radius * 0.32, radius * 0.38);
    canvas.drawPath(smilePath, smilePaint);

    // Bubble specular shine
    canvas.drawCircle(Offset(-radius * 0.4, -radius * 0.4), radius * 0.15, Paint()..color = Colors.white.withValues(alpha: 0.8));

    canvas.restore();
  }

  @override
  bool shouldRepaint(_BubbleCoolPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ============================================================================
// 7. BUBBLE GEM / DIAMOND (:bubble_gem:)
// ============================================================================

class BubbleGemWidget extends StatefulWidget {
  final double size;
  final bool animate;

  const BubbleGemWidget({super.key, required this.size, this.animate = true});

  @override
  State<BubbleGemWidget> createState() => _BubbleGemWidgetState();
}

class _BubbleGemWidgetState extends State<BubbleGemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(BubbleGemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
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
      animation: _controller,
      builder: (context, child) {
        final progress = widget.animate ? _controller.value : 0.0;
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _BubbleGemPainter(progress: progress),
        );
      },
    );
  }
}

class _BubbleGemPainter extends CustomPainter {
  final double progress;

  _BubbleGemPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    // Emerald-cyan crystal sphere
    final sphereRect = Rect.fromCircle(center: Offset.zero, radius: radius);
    final gemGradient = RadialGradient(
      center: const Alignment(-0.25, -0.3),
      radius: 0.95,
      colors: const [
        Color(0xFFE0F2F1),
        Color(0xFF80CBC4),
        Color(0xFF00897B),
        Color(0xFF004D40),
      ],
    );
    canvas.drawCircle(Offset.zero, radius, Paint()..shader = gemGradient.createShader(sphereRect));

    // Faceted diamond shape
    final gemPath = Path();
    final gW = radius * 0.65;
    final gH = radius * 0.55;

    gemPath.moveTo(-gW, -gH * 0.2);
    gemPath.lineTo(-gW * 0.55, -gH);
    gemPath.lineTo(gW * 0.55, -gH);
    gemPath.lineTo(gW, -gH * 0.2);
    gemPath.lineTo(0, gH);
    gemPath.close();

    final diamondPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE0F7FA), Color(0xFF00E5FF), Color(0xFF0091EA)],
      ).createShader(sphereRect);
    canvas.drawPath(gemPath, diamondPaint);

    // Shimmer gleam sweep across facets
    final sheenX = (progress * 2.5 - 1.25) * gW;
    canvas.save();
    canvas.clipPath(gemPath);
    final sheenPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.8),
          Colors.transparent,
        ],
        stops: const [0.35, 0.5, 0.65],
      ).createShader(Rect.fromCenter(center: Offset(sheenX, 0), width: gW, height: gH * 2));
    canvas.drawRect(Rect.fromLTWH(-gW, -gH, gW * 2, gH * 2), sheenPaint);
    canvas.restore();

    // Specular shine
    canvas.drawCircle(Offset(-radius * 0.35, -radius * 0.35), radius * 0.15, Paint()..color = Colors.white.withValues(alpha: 0.8));

    canvas.restore();
  }

  @override
  bool shouldRepaint(_BubbleGemPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ============================================================================
// 8. BUBBLE ROCKET (:bubble_rocket:)
// ============================================================================

class BubbleRocketWidget extends StatefulWidget {
  final double size;
  final bool animate;

  const BubbleRocketWidget({super.key, required this.size, this.animate = true});

  @override
  State<BubbleRocketWidget> createState() => _BubbleRocketWidgetState();
}

class _BubbleRocketWidgetState extends State<BubbleRocketWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(BubbleRocketWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
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
      animation: _controller,
      builder: (context, child) {
        final progress = widget.animate ? _controller.value : 0.0;
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _BubbleRocketPainter(progress: progress),
        );
      },
    );
  }
}

class _BubbleRocketPainter extends CustomPainter {
  final double progress;

  _BubbleRocketPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    // Liftoff vibration
    final vibrate = math.sin(progress * 8 * math.pi) * 1.5;

    canvas.save();
    canvas.translate(center.dx + vibrate * 0.5, center.dy + vibrate);

    // Deep space bubble
    final sphereRect = Rect.fromCircle(center: Offset.zero, radius: radius);
    final spaceGradient = RadialGradient(
      center: const Alignment(-0.2, -0.3),
      radius: 0.95,
      colors: const [
        Color(0xFF311B92),
        Color(0xFF1A237E),
        Color(0xFF000051),
      ],
    );
    canvas.drawCircle(Offset.zero, radius, Paint()..shader = spaceGradient.createShader(sphereRect));

    // Rocket body tilted at 45 degrees
    canvas.save();
    canvas.rotate(-math.pi / 4);

    // Fiery thruster exhaust
    final flameLength = radius * (0.35 + 0.12 * math.sin(progress * 6 * math.pi));
    final flamePath = Path();
    flamePath.moveTo(-radius * 0.15, radius * 0.45);
    flamePath.lineTo(0, radius * 0.45 + flameLength);
    flamePath.lineTo(radius * 0.15, radius * 0.45);
    flamePath.close();
    canvas.drawPath(
      flamePath,
      Paint()..shader = const LinearGradient(colors: [Colors.yellow, Colors.deepOrangeAccent]).createShader(sphereRect),
    );

    // Rocket hull
    final rocketHull = Path();
    rocketHull.moveTo(0, -radius * 0.65);
    rocketHull.cubicTo(radius * 0.35, -radius * 0.2, radius * 0.25, radius * 0.35, radius * 0.2, radius * 0.45);
    rocketHull.lineTo(-radius * 0.2, radius * 0.45);
    rocketHull.cubicTo(-radius * 0.25, radius * 0.35, -radius * 0.35, -radius * 0.2, 0, -radius * 0.65);
    rocketHull.close();
    canvas.drawPath(rocketHull, Paint()..color = Colors.white);

    // Red nosecone
    final nosePath = Path();
    nosePath.moveTo(0, -radius * 0.65);
    nosePath.lineTo(radius * 0.18, -radius * 0.38);
    nosePath.lineTo(-radius * 0.18, -radius * 0.38);
    nosePath.close();
    canvas.drawPath(nosePath, Paint()..color = const Color(0xFFFF1744));

    // Cyan porthole window
    canvas.drawCircle(Offset(0, -radius * 0.12), radius * 0.1, Paint()..color = const Color(0xFF00E5FF));

    canvas.restore();

    // Specular shine
    canvas.drawCircle(Offset(-radius * 0.35, -radius * 0.35), radius * 0.15, Paint()..color = Colors.white.withValues(alpha: 0.8));

    canvas.restore();
  }

  @override
  bool shouldRepaint(_BubbleRocketPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ============================================================================
// 9. BUBBLE 100 (:bubble_100:)
// ============================================================================

class Bubble100Widget extends StatefulWidget {
  final double size;
  final bool animate;

  const Bubble100Widget({super.key, required this.size, this.animate = true});

  @override
  State<Bubble100Widget> createState() => _Bubble100WidgetState();
}

class _Bubble100WidgetState extends State<Bubble100Widget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(Bubble100Widget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
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
      animation: _controller,
      builder: (context, child) {
        final progress = widget.animate ? _controller.value : 0.0;
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _Bubble100Painter(progress: progress),
        );
      },
    );
  }
}

class _Bubble100Painter extends CustomPainter {
  final double progress;

  _Bubble100Painter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    final pulse = 1.0 + 0.07 * math.sin(progress * 2 * math.pi);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(pulse);

    // Glowing scarlet neon sphere
    final sphereRect = Rect.fromCircle(center: Offset.zero, radius: radius);
    final redGradient = RadialGradient(
      center: const Alignment(-0.25, -0.3),
      radius: 0.95,
      colors: const [
        Color(0xFFFF5252),
        Color(0xFFD50000),
        Color(0xFF8B0000),
      ],
    );
    canvas.drawCircle(Offset.zero, radius, Paint()..shader = redGradient.createShader(sphereRect));

    // "100" text painter
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '100',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2 - 2));

    // Double underlines
    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final y1 = radius * 0.42;
    final y2 = radius * 0.58;
    canvas.drawLine(Offset(-radius * 0.55, y1), Offset(radius * 0.55, y1), linePaint);
    canvas.drawLine(Offset(-radius * 0.45, y2), Offset(radius * 0.45, y2), linePaint);

    // Specular shine
    canvas.drawCircle(Offset(-radius * 0.35, -radius * 0.35), radius * 0.15, Paint()..color = Colors.white.withValues(alpha: 0.8));

    canvas.restore();
  }

  @override
  bool shouldRepaint(_Bubble100Painter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ============================================================================
// 10. BUBBLE VERIFIED / SHIELD (:bubble_verified:)
// ============================================================================

class BubbleVerifiedWidget extends StatefulWidget {
  final double size;
  final bool animate;

  const BubbleVerifiedWidget({super.key, required this.size, this.animate = true});

  @override
  State<BubbleVerifiedWidget> createState() => _BubbleVerifiedWidgetState();
}

class _BubbleVerifiedWidgetState extends State<BubbleVerifiedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(BubbleVerifiedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
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
      animation: _controller,
      builder: (context, child) {
        final progress = widget.animate ? _controller.value : 0.0;
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _BubbleVerifiedPainter(progress: progress),
        );
      },
    );
  }
}

class _BubbleVerifiedPainter extends CustomPainter {
  final double progress;

  _BubbleVerifiedPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    final breathe = 1.0 + 0.04 * math.sin(progress * 2 * math.pi);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(breathe);

    // Scalloped badge
    final badgePath = Path();
    const points = 12;
    final rOuter = radius;
    final rInner = radius * 0.85;

    for (int i = 0; i < points * 2; i++) {
      final r = (i % 2 == 0) ? rOuter : rInner;
      final angle = i * math.pi / points;
      final x = math.cos(angle) * r;
      final y = math.sin(angle) * r;
      if (i == 0) {
        badgePath.moveTo(x, y);
      } else {
        badgePath.lineTo(x, y);
      }
    }
    badgePath.close();

    final sphereRect = Rect.fromCircle(center: Offset.zero, radius: radius);
    final cyanGradient = RadialGradient(
      center: const Alignment(-0.25, -0.3),
      colors: const [Color(0xFF00E5FF), Color(0xFF0091EA), Color(0xFF0D47A1)],
    );
    canvas.drawPath(badgePath, Paint()..shader = cyanGradient.createShader(sphereRect));

    // White Checkmark
    final checkPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = radius * 0.22
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final checkPath = Path();
    checkPath.moveTo(-radius * 0.35, -radius * 0.02);
    checkPath.lineTo(-radius * 0.08, radius * 0.26);
    checkPath.lineTo(radius * 0.38, -radius * 0.25);
    canvas.drawPath(checkPath, checkPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_BubbleVerifiedPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
