import 'package:flutter/material.dart';

import '../../shared/widgets/app_scaffold.dart';

class AiCompanionPage extends StatelessWidget {
  const AiCompanionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'AI Companion',
      child: Center(child: Text('AI Companion')),
    );
  }
}
