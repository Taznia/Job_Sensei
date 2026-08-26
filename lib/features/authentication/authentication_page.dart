import 'package:flutter/material.dart';

import '../../app/injector.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/storage/shared_pref.dart';
import '../../core/errors/app_exception.dart';
import '../../shared/models/app_user.dart';
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

  String get _roleLabel => switch (_role) {
        'recruiter' => 'Employer',
        'admin' => 'Admin',
        _ => 'User',
      };

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

  Future<void> _demo() async {
    final credentials = switch (_role) {
      'recruiter' => ('recruiter@jobsensei.app', 'Recruiter123!'),
      'admin' => ('admin@jobsensei.app', 'Admin123!'),
      _ => ('demo@jobsensei.app', 'Demo123!'),
    };
    _email.text = credentials.$1;
    _password.text = credentials.$2;
    _registering = false;
    await _submit();
  }

  @override
  Widget build(BuildContext context) {
    final user = Injector.authService().currentUser;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.onAuthChanged == null
          ? AppBar(title: Text(user == null ? 'Sign in' : 'Account'))
          : null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [
                  AppColors.primaryDark,
                  AppColors.primary,
                  AppColors.cyan
                ]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.psychology_alt_rounded,
                            color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 13),
                      const Text('Job Sensei',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _registering
                        ? 'Build a career that moves with you.'
                        : 'Your next opportunity starts here.',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                      'Personalized guidance, practical tools, and a community for your journey.',
                      style: TextStyle(color: Colors.white70, height: 1.35)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (user != null) ...[
              _SignedInCard(user: user, onSignOut: _signOut),
              const SizedBox(height: 18),
            ],
            Text(
              _registering ? 'Create your Job Sensei account' : 'Welcome back',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Community posts, applications, and saved jobs sync through the backend. Chat with Momo still stays on this device.',
              style: const TextStyle(color: AppColors.muted, height: 1.45),
            ),
            const SizedBox(height: 22),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  if (!_registering) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Sign in as',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          selected: _role == 'seeker',
                          avatar: const Icon(Icons.person_outline_rounded),
                          label: const Text('User'),
                          onSelected: (_) => setState(() => _role = 'seeker'),
                        ),
                        ChoiceChip(
                          selected: _role == 'recruiter',
                          avatar: const Icon(Icons.apartment_rounded),
                          label: const Text('Employer'),
                          onSelected: (_) =>
                              setState(() => _role = 'recruiter'),
                        ),
                        ChoiceChip(
                          selected: _role == 'admin',
                          avatar: const Icon(
                            Icons.admin_panel_settings_outlined,
                          ),
                          label: const Text('Admin'),
                          onSelected: (_) => setState(() => _role = 'admin'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_registering) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Choose account type',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'seeker',
                            icon: Icon(Icons.badge_outlined),
                            label: Text('Job seeker'),
                          ),
                          ButtonSegment(
                            value: 'recruiter',
                            icon: Icon(Icons.apartment_rounded),
                            label: Text('Employer'),
                          ),
                        ],
                        selected: {_role},
                        onSelectionChanged: (roles) => setState(() {
                          _role = roles.first;
                          _error = null;
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isEmployer) ...[
                      TextFormField(
                        controller: _organization,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Organization name',
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                        validator: (value) =>
                            value == null || value.trim().length < 2
                                ? 'Enter your organization name'
                                : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.person_outline_rounded)),
                      validator: (value) =>
                          (value == null || value.trim().length < 2)
                              ? 'Enter your name'
                              : null,
                    ),
                  ],
                  if (_registering) const SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                        labelText: _registering && _isEmployer
                            ? 'Work email address'
                            : 'Email address',
                        prefixIcon: Icon(Icons.mail_outline_rounded)),
                    validator: (value) =>
                        (value == null || !value.contains('@'))
                            ? 'Enter a valid email'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                      ),
                    ),
                    validator: (value) => (value == null || value.length < 8)
                        ? 'Use at least 8 characters'
                        : null,
                  ),
                  if (_registering) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmPassword,
                      obscureText: _obscurePassword,
                      decoration: const InputDecoration(
                        labelText: 'Confirm password',
                        prefixIcon: Icon(Icons.lock_reset_rounded),
                      ),
                      validator: (value) => value != _password.text
                          ? 'Passwords do not match'
                          : null,
                    ),
                    if (_isEmployer) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Admin verification is required before an employer can post jobs or manage applicants.',
                          style: TextStyle(fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ],
                  if (!_registering)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _busy ? null : _showPasswordRecovery,
                        child: const Text('Forgot password?'),
                      ),
                    )
                  else
                    const SizedBox(height: 16),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_registering
                            ? _isEmployer
                                ? 'Submit employer account'
                                : 'Create job seeker account'
                            : 'Sign in'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                              _registering = !_registering;
                              if (_registering && _role == 'admin') {
                                _role = 'seeker';
                              }
                              _error = null;
                            }),
                    child: Text(
                      _registering
                          ? 'Already have an account? Sign in'
                          : 'New here? Create an account',
                    ),
                  ),
                  if (!_registering) ...[
                    OutlinedButton(
                      onPressed: _busy ? null : _demo,
                      child: Text('Continue with $_roleLabel demo'),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Demo accounts after backend seed:\n'
                      'Taznia: demo@jobsensei.app / Demo123!\n'
                      'Nadia: recruiter@jobsensei.app / Recruiter123!\n'
                      'Admin: admin@jobsensei.app / Admin123!',
                      style: TextStyle(
                          color: AppColors.muted, fontSize: 11, height: 1.45),
                    ),
                  ],
                ],
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

class _SignedInCard extends StatelessWidget {
  const _SignedInCard({required this.user, required this.onSignOut});

  final AppUser user;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                  Text(user.name,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(user.email,
                      style: const TextStyle(color: AppColors.muted)),
                ],
              ),
            ),
            TextButton(onPressed: onSignOut, child: const Text('Sign out')),
          ],
        ),
      ),
    );
  }
}
