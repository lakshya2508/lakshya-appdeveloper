import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/realtime_colors.dart';

/// Haikei-inspired generative layered waves CustomPainter.
/// Draws 3 organic cubic Bezier wave bands with smooth gradient fills and floating phase offset.
class HaikeiLayeredWavesPainter extends CustomPainter {
  HaikeiLayeredWavesPainter({
    required this.progress,
    required this.primary,
    required this.secondary,
    required this.accent,
    this.flip = false,
    this.alertFlashColor,
  });

  final double progress;
  final Color primary;
  final Color secondary;
  final Color accent;
  final bool flip;
  final Color? alertFlashColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    canvas.save();
    if (flip) {
      canvas.translate(0, size.height);
      canvas.scale(1.0, -1.0);
    }

    final p1 = alertFlashColor ?? primary;
    final p2 = alertFlashColor ?? secondary;
    final p3 = alertFlashColor ?? accent;

    final phaseA = progress * 2 * math.pi;
    final phaseB = progress * 2.4 * math.pi;
    final phaseC = progress * 1.8 * math.pi;

    // Layer 1: Deep wave
    final paint1 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          p1.withAlpha(alertFlashColor != null ? 80 : 35),
          p2.withAlpha(alertFlashColor != null ? 100 : 55),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path1 = Path();
    path1.moveTo(0, size.height * 0.55 + math.sin(phaseA) * 12);
    path1.cubicTo(
      size.width * 0.28,
      size.height * 0.35 + math.cos(phaseA) * 14,
      size.width * 0.65,
      size.height * 0.75 + math.sin(phaseA) * 16,
      size.width,
      size.height * 0.45 + math.cos(phaseA) * 10,
    );
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint1);

    // Layer 2: Mid wave
    final paint2 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [
          p2.withAlpha(alertFlashColor != null ? 90 : 45),
          p3.withAlpha(alertFlashColor != null ? 110 : 40),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path2 = Path();
    path2.moveTo(0, size.height * 0.70 + math.cos(phaseB) * 10);
    path2.cubicTo(
      size.width * 0.35,
      size.height * 0.85 + math.sin(phaseB) * 12,
      size.width * 0.72,
      size.height * 0.40 + math.cos(phaseB) * 15,
      size.width,
      size.height * 0.60 + math.sin(phaseB) * 10,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);

    // Layer 3: Foreground crest
    final paint3 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          p1.withAlpha(alertFlashColor != null ? 100 : 25),
          p2.withAlpha(alertFlashColor != null ? 120 : 50),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path3 = Path();
    path3.moveTo(0, size.height * 0.80 + math.sin(phaseC) * 8);
    path3.cubicTo(
      size.width * 0.22,
      size.height * 0.60 + math.cos(phaseC) * 10,
      size.width * 0.58,
      size.height * 0.88 + math.sin(phaseC) * 12,
      size.width,
      size.height * 0.72 + math.cos(phaseC) * 8,
    );
    path3.lineTo(size.width, size.height);
    path3.lineTo(0, size.height);
    path3.close();
    canvas.drawPath(path3, paint3);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HaikeiLayeredWavesPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.accent != accent ||
        oldDelegate.alertFlashColor != alertFlashColor;
  }
}

/// Organic morphing Haikei Blob Painter.
class HaikeiBlobPainter extends CustomPainter {
  HaikeiBlobPainter({
    required this.progress,
    required this.primary,
    required this.accent,
  });

  final double progress;
  final Color primary;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = math.min(size.width, size.height) * 0.42;
    const numPoints = 7;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          primary.withAlpha(60),
          accent.withAlpha(30),
          Colors.transparent,
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius * 1.3));

    final path = Path();
    final angleStep = (math.pi * 2) / numPoints;

    final points = <Offset>[];
    for (var i = 0; i < numPoints; i++) {
      final angle = i * angleStep;
      final wave = math.sin(progress * 2 * math.pi + i * 1.5) * (baseRadius * 0.18);
      final r = baseRadius + wave;
      points.add(Offset(
        center.dx + math.cos(angle) * r,
        center.dy + math.sin(angle) * r,
      ));
    }

    path.moveTo(
      (points[0].dx + points[numPoints - 1].dx) / 2,
      (points[0].dy + points[numPoints - 1].dy) / 2,
    );

    for (var i = 0; i < numPoints; i++) {
      final current = points[i];
      final next = points[(i + 1) % numPoints];
      final mid = Offset((current.dx + next.dx) / 2, (current.dy + next.dy) / 2);
      path.quadraticBezierTo(current.dx, current.dy, mid.dx, mid.dy);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant HaikeiBlobPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primary != primary ||
        oldDelegate.accent != accent;
  }
}

/// Fullscreen ambient animated canvas with Haikei organic waves and floating glowing orbs.
class HaikeiAmbientCanvas extends StatefulWidget {
  const HaikeiAmbientCanvas({
    super.key,
    required this.palette,
    required this.isDark,
    required this.child,
    this.alertFlashColor,
  });

  final RealtimePalette palette;
  final bool isDark;
  final Widget child;
  final Color? alertFlashColor;

  @override
  State<HaikeiAmbientCanvas> createState() => _HaikeiAmbientCanvasState();
}

class _HaikeiAmbientCanvasState extends State<HaikeiAmbientCanvas> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool get _canAnimate {
    if (WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations) return false;
    if (WidgetsBinding.instance.runtimeType.toString().contains('Test')) return false;
    return true;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
    if (_canAnimate) {
      _controller.repeat();
    } else {
      _controller.value = 0.4;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pal = widget.palette;

    return Stack(
      children: [
        // Background canvas solid
        Positioned.fill(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            color: pal.canvas(widget.isDark),
          ),
        ),

        // Animated Haikei Top Waves
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 190,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: HaikeiLayeredWavesPainter(
                progress: _controller.value,
                primary: pal.primary,
                secondary: pal.secondary,
                accent: pal.accent,
                flip: true,
                alertFlashColor: widget.alertFlashColor,
              ),
            ),
          ),
        ),

        // Floating ambient orbs
        Positioned(
          right: -40,
          top: 140,
          width: 260,
          height: 260,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: HaikeiBlobPainter(
                progress: _controller.value,
                primary: pal.primary,
                accent: pal.accent,
              ),
            ),
          ),
        ),

        // Animated Haikei Bottom Waves
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 220,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: HaikeiLayeredWavesPainter(
                progress: _controller.value,
                primary: pal.primary,
                secondary: pal.secondary,
                accent: pal.accent,
                flip: false,
                alertFlashColor: widget.alertFlashColor,
              ),
            ),
          ),
        ),

        // Content
        Positioned.fill(child: widget.child),
      ],
    );
  }
}
