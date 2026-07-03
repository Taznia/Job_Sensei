import 'package:flutter/material.dart';

import '../../shared/widgets/app_scaffold.dart';

class AiPage extends StatelessWidget {
  const AiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'AI',
      child: Center(child: Text('AI Companion')),
    );
  }
}
