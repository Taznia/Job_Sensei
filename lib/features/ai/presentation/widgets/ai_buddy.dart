import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class AiBuddy extends StatefulWidget {
  const AiBuddy({
    super.key,
    this.size = 58,
    this.isThinking = false,
    this.showGreeting = false,
  });

  final double size;
  final bool isThinking;
  final bool showGreeting;

  @override
  State<AiBuddy> createState() => _AiBuddyState();
}

class _AiBuddyState extends State<AiBuddy> with TickerProviderStateMixin {
  late final AnimationController _motionController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  )..repeat();
  late final AnimationController _greetingController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  @override
  void initState() {
    super.initState();
    if (widget.showGreeting) {
      _greetingController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant AiBuddy oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showGreeting && !oldWidget.showGreeting) {
      _greetingController.forward(from: 0);
    } else if (!widget.showGreeting && oldWidget.showGreeting) {
      _greetingController.reverse();
    }
  }

  @override
  void dispose() {
    _motionController.dispose();
    _greetingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final greetingWidth = widget.showGreeting ? widget.size * 1.55 : 0.0;
    return Semantics(
      label: widget.showGreeting ? 'Momo says hi' : 'Momo AI buddy',
      image: true,
      child: SizedBox(
        width: widget.size + greetingWidth,
        height: widget.size * 1.15,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _motionController,
            _greetingController,
          ]),
          builder: (context, _) {
            final phase = _motionController.value * 6.283185307;
            final lift = -2.4 * (0.5 + 0.5 * math.sin(phase));
            final blink = _eyeOpenness(_motionController.value);
            final wave = widget.showGreeting
                ? -0.35 + math.sin(phase * 2) * 0.24
                : -0.12 + math.sin(phase) * 0.08;
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                Transform.translate(
                  offset: Offset(0, lift),
                  child: _BuddyBody(
                    size: widget.size,
                    isThinking: widget.isThinking,
                    eyeOpenness: blink,
                    waveAngle: wave,
                    pulse: 0.5 + 0.5 * math.sin(phase),
                  ),
                ),
                if (widget.showGreeting)
                  Positioned(
                    left: widget.size * 0.92,
                    top: widget.size * 0.02,
                    child: FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _greetingController,
                        curve: Curves.easeOut,
                      ),
                      child: ScaleTransition(
                        alignment: Alignment.bottomLeft,
                        scale: Tween<double>(begin: 0.72, end: 1).animate(
                          CurvedAnimation(
                            parent: _greetingController,
                            curve: Curves.elasticOut,
                          ),
                        ),
                        child: const _GreetingBubble(),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  double _eyeOpenness(double progress) {
    final blinkOne = progress > 0.44 && progress < 0.49;
    final blinkTwo = progress > 0.82 && progress < 0.85;
    return blinkOne || blinkTwo ? 0.12 : 1;
  }
}

class _BuddyBody extends StatelessWidget {
  const _BuddyBody({
    required this.size,
    required this.isThinking,
    required this.eyeOpenness,
    required this.waveAngle,
    required this.pulse,
  });

  final double size;
  final bool isThinking;
  final double eyeOpenness;
  final double waveAngle;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: 0.96 + pulse * 0.06,
            child: Container(
              width: size * 0.92,
              height: size * 0.92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.cyan.withOpacity(isThinking ? 0.28 : 0.16),
                    AppColors.primary.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          if (isThinking)
            Transform.rotate(
              angle: pulse * 3.14,
              child: Container(
                margin: EdgeInsets.all(size * 0.015),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.cyan.withOpacity(0.38),
                    width: size * 0.025,
                  ),
                ),
              ),
            ),
          Positioned(
            right: -size * 0.015,
            top: size * 0.46,
            child: Transform.rotate(
              angle: waveAngle,
              alignment: Alignment.bottomLeft,
              child: Container(
                width: size * 0.26,
                height: size * 0.13,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B75FF), AppColors.cyan],
                  ),
                  borderRadius: BorderRadius.circular(size),
                  border: Border.all(
                    color: Colors.white,
                    width: size * 0.025,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: size * 0.01,
            child: Container(
              width: size * 0.075,
              height: size * 0.22,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.cyan, AppColors.primary],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(size),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Container(
              width: size * 0.14,
              height: size * 0.14,
              decoration: BoxDecoration(
                color: AppColors.cyan,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: size * 0.018),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyan.withOpacity(0.7),
                    blurRadius: size * 0.12,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: size * 0.04,
            child: Container(
              width: size * 0.82,
              height: size * 0.71,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1768ED),
                    Color(0xFF168FF5),
                    AppColors.cyan
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(size * 0.3),
                border: Border.all(color: Colors.white, width: size * 0.038),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: size * 0.25,
                    offset: Offset(0, size * 0.1),
                  ),
                  BoxShadow(
                    color: AppColors.cyan.withOpacity(0.18),
                    blurRadius: size * 0.4,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: size * 0.18,
                    top: size * 0.22,
                    child: _BuddyEye(
                      size: size * 0.12,
                      openness: eyeOpenness,
                    ),
                  ),
                  Positioned(
                    right: size * 0.18,
                    top: size * 0.22,
                    child: _BuddyEye(
                      size: size * 0.12,
                      openness: eyeOpenness,
                    ),
                  ),
                  Positioned(
                    left: size * 0.25,
                    right: size * 0.25,
                    bottom: size * 0.1,
                    child: SizedBox(
                      height: size * 0.14,
                      child: CustomPaint(
                        painter: _BuddySmilePainter(
                          color: Colors.white.withOpacity(0.95),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: size * 0.08,
                    top: size * 0.08,
                    child: Container(
                      width: size * 0.16,
                      height: size * 0.07,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.17),
                        borderRadius: BorderRadius.circular(size),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuddyEye extends StatelessWidget {
  const _BuddyEye({required this.size, required this.openness});

  final double size;
  final double openness;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      width: size,
      height: size * openness,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: openness < 0.5
          ? null
          : CircleAvatar(
              radius: size * 0.23,
              backgroundColor: const Color(0xFF103C75),
            ),
    );
  }
}

class _BuddySmilePainter extends CustomPainter {
  const _BuddySmilePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.12, size.height * 0.28)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.92,
        size.width * 0.88,
        size.height * 0.28,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = size.height * 0.18,
    );
  }

  @override
  bool shouldRepaint(covariant _BuddySmilePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _GreetingBubble extends StatelessWidget {
  const _GreetingBubble();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(18),
          bottomLeft: Radius.circular(5),
        ),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.14),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hi! I\'m Momo',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Ready when you are.',
            style: TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
