import 'dart:math' as math;

import 'package:flutter/material.dart';

class AnimatedAiBackground extends StatefulWidget {
  const AnimatedAiBackground({super.key});

  @override
  State<AnimatedAiBackground> createState() => _AnimatedAiBackgroundState();
}

class _AnimatedAiBackgroundState extends State<AnimatedAiBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _AiAtmospherePainter(progress: _controller.value),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _AiAtmospherePainter extends CustomPainter {
  const _AiAtmospherePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFFF8FBFF),
            Color(0xFFEAF4FF),
            Color(0xFFF3FAFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
    );

    final phase = progress * math.pi * 2;
    _drawGlow(
      canvas,
      size,
      center: Offset(
        size.width * (0.78 + math.sin(phase) * 0.08),
        size.height * (0.24 + math.cos(phase * 0.7) * 0.08),
      ),
      radius: size.shortestSide * 0.55,
      color: const Color(0xFF61D8FF),
      opacity: 0.2,
    );
    _drawGlow(
      canvas,
      size,
      center: Offset(
        size.width * (0.15 + math.cos(phase * 0.8) * 0.1),
        size.height * (0.73 + math.sin(phase * 0.55) * 0.09),
      ),
      radius: size.shortestSide * 0.62,
      color: const Color(0xFF2B79FF),
      opacity: 0.13,
    );
    _drawGlow(
      canvas,
      size,
      center: Offset(
        size.width * (0.5 + math.sin(phase * 0.45) * 0.16),
        size.height * (0.48 + math.cos(phase * 0.6) * 0.12),
      ),
      radius: size.shortestSide * 0.38,
      color: const Color(0xFF83A7FF),
      opacity: 0.1,
    );

    _drawAuroraRibbon(canvas, size, phase, 0.36, 0.045);
    _drawAuroraRibbon(canvas, size, phase + 2.2, 0.62, 0.03);
    _drawParticles(canvas, size, phase);
  }

  void _drawGlow(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radius,
    required Color color,
    required double opacity,
  }) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withOpacity(opacity), color.withOpacity(0)],
        ).createShader(rect),
    );
  }

  void _drawAuroraRibbon(
    Canvas canvas,
    Size size,
    double phase,
    double verticalPosition,
    double opacity,
  ) {
    final path = Path()..moveTo(-40, size.height * verticalPosition);
    final amplitude = size.height * 0.065;
    for (double x = -40; x <= size.width + 40; x += 24) {
      final y = size.height * verticalPosition +
          math.sin((x / math.max(size.width, 1)) * math.pi * 2 + phase) *
              amplitude;
      path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF237BFF).withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
  }

  void _drawParticles(Canvas canvas, Size size, double phase) {
    const particles = [
      (0.08, 0.18, 2.2, 0.4),
      (0.19, 0.42, 1.4, 1.7),
      (0.31, 0.12, 1.7, 2.5),
      (0.45, 0.68, 2.1, 3.2),
      (0.59, 0.24, 1.5, 4.1),
      (0.72, 0.58, 1.9, 4.8),
      (0.84, 0.15, 1.3, 5.5),
      (0.91, 0.77, 2.0, 0.9),
      (0.13, 0.82, 1.5, 3.7),
      (0.66, 0.87, 1.2, 2.1),
    ];
    for (final particle in particles) {
      final drift = math.sin(phase + particle.$4) * 10;
      final pulse = 0.45 + math.sin(phase * 1.3 + particle.$4) * 0.2;
      canvas.drawCircle(
        Offset(size.width * particle.$1 + drift, size.height * particle.$2),
        particle.$3,
        Paint()..color = const Color(0xFF4D9BFF).withOpacity(pulse),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AiAtmospherePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
