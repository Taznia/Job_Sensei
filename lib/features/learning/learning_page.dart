import 'package:flutter/material.dart';

import '../../shared/widgets/app_scaffold.dart';

class LearningPage extends StatelessWidget {
  const LearningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Learning',
      child: Center(child: Text('Learning')),
    );
  }
}
