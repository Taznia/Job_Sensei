import 'package:flutter/material.dart';

import '../../shared/widgets/app_scaffold.dart';

class AuthenticationPage extends StatelessWidget {
  const AuthenticationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Authentication',
      child: Center(
        child: FilledButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/jobs'),
          child: const Text('Continue'),
        ),
      ),
    );
  }
}
