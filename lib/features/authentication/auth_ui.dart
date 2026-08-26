import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';

/// Visual language for the login / register screens.
///
/// Matches the referenced auth layout (corner blob, floating focused field,
/// right-aligned gradient CTA) while staying on the Job Sensei palette.
abstract final class AuthUi {
  static const canvas = Color(0xFFF7F8FC);
  static const ink = Color(0xFF1A1D26);
  static const muted = Color(0xFF9AA0AE);
  static const line = Color(0xFFE4E7EE);

  static const String? fontFamily = null;

  static const title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 34,
    height: 1.15,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    color: ink,
  );

  static const subtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 1.35,
    fontWeight: FontWeight.w400,
    color: muted,
  );

  static const label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.35,
    color: muted,
  );

  static const field = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 1.25,
    fontWeight: FontWeight.w700,
    color: ink,
  );

  static const cta = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.1,
    color: Colors.white,
  );

  static const gradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF3BA0FF),
      AppColors.primary,
      AppColors.primaryDark,
    ],
  );
}

class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: AuthUi.canvas),
        Positioned(
          top: -56,
          right: -48,
          child: IgnorePointer(
            child: SizedBox(
              width: 228,
              height: 214,
              child: CustomPaint(painter: _AuthBlobPainter()),
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthBlobPainter extends CustomPainter {
  const _AuthBlobPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;

    final back = Path()
      ..moveTo(size.width * 0.22, 0)
      ..cubicTo(
        size.width * 0.02,
        size.height * 0.22,
        size.width * 0.08,
        size.height * 0.72,
        size.width * 0.48,
        size.height * 0.90,
      )
      ..cubicTo(
        size.width * 0.78,
        size.height * 1.04,
        size.width * 1.06,
        size.height * 0.68,
        size.width,
        size.height * 0.18,
      )
      ..lineTo(size.width, 0)
      ..close();

    final front = Path()
      ..moveTo(size.width * 0.38, 0)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.28,
        size.width * 0.32,
        size.height * 0.78,
        size.width * 0.70,
        size.height * 0.74,
      )
      ..cubicTo(
        size.width * 0.98,
        size.height * 0.70,
        size.width * 1.08,
        size.height * 0.32,
        size.width,
        0,
      )
      ..close();

    canvas.drawPath(
      back,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7EC8FF), Color(0xFF2F7BFF)],
        ).createShader(bounds),
    );
    canvas.drawPath(
      front,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.cyan, AppColors.primaryDark],
        ).createShader(bounds),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.textInputAction,
    this.enabled = true,
    this.autofocus = false,
    this.trailing,
    this.onFieldSubmitted,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final bool enabled;
  final bool autofocus;
  final Widget? trailing;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late final FocusNode _focus = FocusNode();
  var _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() {
    if (_focused == _focus.hasFocus) return;
    setState(() => _focused = _focus.hasFocus);
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focused;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 6),
      padding: EdgeInsets.fromLTRB(
          focused ? 14 : 0, focused ? 6 : 0, focused ? 8 : 0, focused ? 6 : 0),
      decoration: BoxDecoration(
        color: focused ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ]
            : const [],
      ),
      child: TextFormField(
        focusNode: _focus,
        controller: widget.controller,
        validator: widget.validator,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        textCapitalization: widget.textCapitalization,
        autofillHints: widget.autofillHints,
        textInputAction: widget.textInputAction,
        enabled: widget.enabled,
        autofocus: widget.autofocus,
        onFieldSubmitted: widget.onFieldSubmitted,
        style: AuthUi.field,
        cursorColor: AppColors.primary,
        inputFormatters: [
          if (widget.keyboardType == TextInputType.emailAddress)
            FilteringTextInputFormatter.deny(RegExp(r'\s')),
        ],
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          prefixIcon: Icon(
            widget.icon,
            size: 22,
            color: focused ? AppColors.primary : AuthUi.muted,
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          labelText: widget.label,
          labelStyle: AuthUi.label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          floatingLabelStyle: AuthUi.label,
          suffixIcon: widget.trailing,
          suffixIconConstraints: const BoxConstraints(
            minHeight: 36,
            minWidth: 36,
          ),
          contentPadding: const EdgeInsets.fromLTRB(0, 18, 8, 12),
          border: _border(focused, AuthUi.line),
          enabledBorder: _border(focused, AuthUi.line),
          focusedBorder: _border(focused, Colors.transparent),
          disabledBorder: _border(focused, AuthUi.line),
          errorBorder: _border(focused, AppColors.danger),
          focusedErrorBorder: _border(focused, AppColors.danger),
          errorStyle: const TextStyle(
            fontFamily: AuthUi.fontFamily,
            color: AppColors.danger,
            fontSize: 12,
            height: 1.2,
          ),
        ),
      ),
    );
  }

  InputBorder _border(bool focused, Color color) {
    if (focused) return InputBorder.none;
    return UnderlineInputBorder(
      borderSide: BorderSide(color: color, width: 1.15),
    );
  }
}

class AuthRoleChip extends StatelessWidget {
  const AuthRoleChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? AppColors.primary : AuthUi.line,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : AuthUi.muted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AuthUi.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AuthUi.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthGradientButton extends StatelessWidget {
  const AuthGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    return Align(
      alignment: Alignment.centerRight,
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AuthUi.gradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.38),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? onPressed : null,
              borderRadius: BorderRadius.circular(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 148, minHeight: 54),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  child: busy
                      ? const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(label, style: AuthUi.cta),
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthFooterPrompt extends StatelessWidget {
  const AuthFooterPrompt({
    super.key,
    required this.prompt,
    required this.action,
    required this.onTap,
  });

  final String prompt;
  final String action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          prompt,
          style: const TextStyle(
            fontFamily: AuthUi.fontFamily,
            color: AuthUi.muted,
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            action,
            style: const TextStyle(
              fontFamily: AuthUi.fontFamily,
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
