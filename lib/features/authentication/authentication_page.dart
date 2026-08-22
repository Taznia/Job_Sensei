import 'package:flutter/material.dart';

import '../../app/injector.dart';
import '../../core/constants/app_colors.dart';
import '../../core/errors/app_exception.dart';
import '../../shared/models/app_user.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({super.key, this.onAuthChanged});

  final VoidCallback? onAuthChanged;

  @override
  State<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _registering = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
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
        await auth.register(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
        );
      } else {
        await auth.login(
          email: _email.text.trim(),
          password: _password.text,
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

  Future<void> _demo() async {
    _email.text = 'demo@jobsensei.app';
    _password.text = 'Demo123!';
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
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
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
                if (_registering)
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Full name'),
                    validator: (value) =>
                        (value == null || value.trim().length < 2)
                            ? 'Enter your name'
                            : null,
                  ),
                if (_registering) const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) =>
                      (value == null || !value.contains('@'))
                          ? 'Enter a valid email'
                          : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (value) => (value == null || value.length < 8)
                      ? 'Use at least 8 characters'
                      : null,
                ),
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
                      : Text(_registering ? 'Create account' : 'Sign in'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _registering = !_registering),
                  child: Text(
                    _registering
                        ? 'Already have an account? Sign in'
                        : 'New here? Create an account',
                  ),
                ),
                OutlinedButton(
                  onPressed: _busy ? null : _demo,
                  child: const Text('Continue with demo account'),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
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
