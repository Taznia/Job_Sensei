import 'package:flutter/material.dart';

import '../../app/injector.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/storage/shared_pref.dart';
import '../../core/errors/app_exception.dart';
import '../../core/widgets/app_widgets.dart';
import '../../shared/models/app_user.dart';
import 'auth_ui.dart';
import 'password_recovery_dialog.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage(
      {super.key, this.onAuthChanged, this.register = false});

  final VoidCallback? onAuthChanged;
  final bool register;

  @override
  State<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _organization = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _registering = false;
  bool _busy = false;
  bool _obscurePassword = true;
  String _role = 'seeker';
  String? _error;

  bool get _isEmployer => _role == 'recruiter';

  @override
  void initState() {
    super.initState();
    _registering = widget.register;
    SharedPref().getString(AppConstants.cachedUserEmailKey).then((email) {
      if (mounted && email != null && email.isNotEmpty) _email.text = email;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _organization.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = Injector.authService();
      if (_registering) {
        final user = await auth.register(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          role: _role,
          organizationName: _isEmployer ? _organization.text.trim() : null,
        );
        if (!mounted) return;
        if (user.role == 'recruiter' && user.employerStatus == 'pending') {
          await _showEmployerPendingDialog(user);
        }
      } else {
        await auth.login(
          email: _email.text.trim(),
          password: _password.text,
          role: _role,
        );
      }
      if (!mounted) return;
      widget.onAuthChanged?.call();
      if (widget.onAuthChanged == null) {
        Navigator.pop(context, true);
      }
    } on AppException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Could not sign in. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showEmployerPendingDialog(AppUser user) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.verified_user_outlined,
          color: AppColors.warning,
          size: 36,
        ),
        title: const Text('Employer account submitted'),
        content: Text(
          'Your account for ${user.organizationName} is waiting for admin '
          'verification. Employer-only actions stay locked until approval.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _toggleMode() {
    setState(() {
      _registering = !_registering;
      if (_registering && _role == 'admin') {
        _role = 'seeker';
      }
      _error = null;
    });
  }

  void _onBack() {
    final canPop =
        widget.onAuthChanged == null && Navigator.of(context).canPop();
    if (_registering) {
      setState(() {
        _registering = false;
        _error = null;
      });
      return;
    }
    if (canPop) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final user = Injector.authService().currentUser;
    final canPop =
        widget.onAuthChanged == null && Navigator.of(context).canPop();
    final showBack = canPop || _registering;

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Roboto'),
        splashFactory: InkRipple.splashFactory,
      ),
      child: Scaffold(
        backgroundColor: AuthUi.canvas,
        body: Stack(
          children: [
            const AuthBackdrop(),
            SafeArea(
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 4, 28, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showBack)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: _busy ? null : _onBack,
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 18,
                                color: AuthUi.muted,
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: AppLogo(height: 30),
                        ),
                        const SizedBox(height: 28),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: Align(
                            key: ValueKey(_registering),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _registering ? 'Create Account' : 'Login',
                              style: AuthUi.title,
                            ),
                          ),
                        ),
                        if (!_registering) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Please sign in to continue.',
                            style: AuthUi.subtitle,
                          ),
                        ],
                        const SizedBox(height: 32),
                        if (user != null) ...[
                          _SignedInCard(user: user, onSignOut: _signOut),
                          const SizedBox(height: 22),
                        ],
                        _RoleRow(
                          registering: _registering,
                          role: _role,
                          enabled: !_busy,
                          onChanged: (role) => setState(() {
                            _role = role;
                            _error = null;
                          }),
                        ),
                        const SizedBox(height: 10),
                        if (_registering) ...[
                          if (_isEmployer) ...[
                            AuthTextField(
                              label: 'ORGANIZATION',
                              icon: Icons.business_outlined,
                              controller: _organization,
                              textCapitalization: TextCapitalization.words,
                              autofillHints: const [
                                AutofillHints.organizationName
                              ],
                              textInputAction: TextInputAction.next,
                              enabled: !_busy,
                              autofocus: true,
                              validator: (value) =>
                                  value == null || value.trim().length < 2
                                      ? 'Enter your organization name'
                                      : null,
                            ),
                          ],
                          AuthTextField(
                            label: 'FULL NAME',
                            icon: Icons.person_outline_rounded,
                            controller: _name,
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.name],
                            textInputAction: TextInputAction.next,
                            enabled: !_busy,
                            autofocus: !_isEmployer,
                            validator: (value) =>
                                (value == null || value.trim().length < 2)
                                    ? 'Enter your name'
                                    : null,
                          ),
                        ],
                        AuthTextField(
                          label: _registering && _isEmployer
                              ? 'WORK EMAIL'
                              : 'EMAIL',
                          icon: Icons.mail_outline_rounded,
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          textInputAction: TextInputAction.next,
                          enabled: !_busy,
                          autofocus: !_registering,
                          validator: (value) =>
                              (value == null || !value.contains('@'))
                                  ? 'Enter a valid email'
                                  : null,
                        ),
                        AuthTextField(
                          label: 'PASSWORD',
                          icon: Icons.lock_outline_rounded,
                          controller: _password,
                          obscureText: _obscurePassword,
                          autofillHints: [
                            _registering
                                ? AutofillHints.newPassword
                                : AutofillHints.password,
                          ],
                          textInputAction: _registering
                              ? TextInputAction.next
                              : TextInputAction.done,
                          enabled: !_busy,
                          onFieldSubmitted: (_) {
                            if (!_registering) _submit();
                          },
                          validator: (value) =>
                              (value == null || value.length < 8)
                                  ? 'Use at least 8 characters'
                                  : null,
                          trailing: _PasswordTrailing(
                            obscure: _obscurePassword,
                            showForgot: !_registering,
                            enabled: !_busy,
                            onToggleObscure: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            onForgot: _showPasswordRecovery,
                          ),
                        ),
                        if (_registering) ...[
                          AuthTextField(
                            label: 'CONFIRM PASSWORD',
                            icon: Icons.lock_outline_rounded,
                            controller: _confirmPassword,
                            obscureText: _obscurePassword,
                            autofillHints: const [AutofillHints.newPassword],
                            textInputAction: TextInputAction.done,
                            enabled: !_busy,
                            validator: (value) => value != _password.text
                                ? 'Passwords do not match'
                                : null,
                          ),
                          if (_isEmployer) ...[
                            const SizedBox(height: 4),
                            const Text(
                              'Admin verification is required before an employer can post jobs or manage applicants.',
                              style: TextStyle(
                                fontFamily: AuthUi.fontFamily,
                                color: AuthUi.muted,
                                fontSize: 12,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _error!,
                            style: const TextStyle(
                              fontFamily: AuthUi.fontFamily,
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        AuthGradientButton(
                          label: _registering ? 'SIGN UP' : 'LOGIN',
                          busy: _busy,
                          onPressed: _busy ? null : _submit,
                        ),
                        const SizedBox(height: 36),
                        AuthFooterPrompt(
                          prompt: _registering
                              ? 'Already have an account? '
                              : "Don't have an account? ",
                          action: _registering ? 'Sign in' : 'Sign up',
                          onTap: _busy ? null : _toggleMode,
                        ),
                        if (!_registering) ...[
                          const SizedBox(height: 24),
                          const Text(
                            'Test accounts\n'
                            'User: demo@jobsensei.app / Demo123!\n'
                            'Employer: recruiter@jobsensei.app / Recruiter123!\n'
                            'Admin: admin@jobsensei.app / Admin123!',
                            style: TextStyle(
                              color: AuthUi.muted,
                              fontSize: 11,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPasswordRecovery() async {
    final reset = await showDialog<bool>(
      context: context,
      builder: (_) => PasswordRecoveryDialog(
        initialEmail: _email.text.trim(),
      ),
    );
    if (reset == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated. Sign in with your new password.'),
        ),
      );
    }
  }

  Future<void> _signOut() async {
    await Injector.authService().logout();
    if (mounted) setState(() {});
  }
}

class _RoleRow extends StatelessWidget {
  const _RoleRow({
    required this.registering,
    required this.role,
    required this.enabled,
    required this.onChanged,
  });

  final bool registering;
  final String role;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final chips = registering
        ? [
            (value: 'seeker', label: 'Job seeker', icon: Icons.badge_outlined),
            (
              value: 'recruiter',
              label: 'Employer',
              icon: Icons.apartment_rounded
            ),
          ]
        : [
            (
              value: 'seeker',
              label: 'User',
              icon: Icons.person_outline_rounded
            ),
            (
              value: 'recruiter',
              label: 'Employer',
              icon: Icons.apartment_rounded
            ),
            (
              value: 'admin',
              label: 'Admin',
              icon: Icons.admin_panel_settings_outlined
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          registering ? 'ACCOUNT TYPE' : 'SIGN IN AS',
          style: AuthUi.label,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final chip in chips)
              AuthRoleChip(
                label: chip.label,
                icon: chip.icon,
                selected: role == chip.value,
                onTap: enabled ? () => onChanged(chip.value) : () {},
              ),
          ],
        ),
      ],
    );
  }
}

class _PasswordTrailing extends StatelessWidget {
  const _PasswordTrailing({
    required this.obscure,
    required this.showForgot,
    required this.enabled,
    required this.onToggleObscure,
    required this.onForgot,
  });

  final bool obscure;
  final bool showForgot;
  final bool enabled;
  final VoidCallback onToggleObscure;
  final VoidCallback onForgot;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: enabled ? onToggleObscure : null,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: Icon(
              obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
              color: AuthUi.muted,
            ),
          ),
          if (showForgot)
            TextButton(
              onPressed: enabled ? onForgot : null,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text(
                'FORGOT',
                style: TextStyle(
                  fontFamily: AuthUi.fontFamily,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SignedInCard extends StatelessWidget {
  const _SignedInCard({required this.user, required this.onSignOut});

  final AppUser user;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            child: Text(user.name.isEmpty ? '?' : user.name[0].toUpperCase()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontFamily: AuthUi.fontFamily,
                    fontWeight: FontWeight.w800,
                    color: AuthUi.ink,
                  ),
                ),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontFamily: AuthUi.fontFamily,
                    color: AuthUi.muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onSignOut,
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
