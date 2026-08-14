import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class AiBuddy extends StatefulWidget {
  const AiBuddy({
    super.key,
    this.size = 58,
    this.isThinking = false,
  });

  final double size;
  final bool isThinking;

  @override
  State<AiBuddy> createState() => _AiBuddyState();
}

class _AiBuddyState extends State<AiBuddy> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);

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
        final lift = widget.isThinking
            ? -2.5 * _controller.value
            : -1.5 * _controller.value;
        return Transform.translate(offset: Offset(0, lift), child: child);
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (widget.isThinking)
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.cyan.withOpacity(0.25),
                    width: 3,
                  ),
                ),
              ),
            Positioned(
              top: widget.size * 0.03,
              child: Container(
                width: widget.size * 0.09,
                height: widget.size * 0.2,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            Positioned(
              top: 0,
              child: CircleAvatar(
                radius: widget.size * 0.055,
                backgroundColor: AppColors.cyan,
              ),
            ),
            Positioned(
              bottom: widget.size * 0.04,
              child: Container(
                width: widget.size * 0.82,
                height: widget.size * 0.72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.primary,
                      Color(0xFF168FF5),
                      AppColors.cyan
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(widget.size * 0.3),
                  border: Border.all(
                      color: Colors.white, width: widget.size * 0.04),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: widget.size * 0.25,
                      offset: Offset(0, widget.size * 0.1),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: widget.size * 0.2,
                      top: widget.size * 0.23,
                      child: _BuddyEye(size: widget.size * 0.11),
                    ),
                    Positioned(
                      right: widget.size * 0.2,
                      top: widget.size * 0.23,
                      child: _BuddyEye(size: widget.size * 0.11),
                    ),
                    Positioned(
                      left: widget.size * 0.3,
                      right: widget.size * 0.3,
                      bottom: widget.size * 0.13,
                      child: Container(
                        height: widget.size * 0.045,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuddyEye extends StatelessWidget {
  const _BuddyEye({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration:
          const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: CircleAvatar(
        radius: size * 0.22,
        backgroundColor: const Color(0xFF123B73),
      ),
    );
  }
}
