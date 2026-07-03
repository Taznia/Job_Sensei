import 'package:flutter/material.dart';

import '../../shared/widgets/app_scaffold.dart';

class ResumesPage extends StatelessWidget {
  const ResumesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Resumes',
      child: Center(child: Text('Resumes')),
    );
  }
}
