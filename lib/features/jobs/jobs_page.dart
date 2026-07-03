import 'package:flutter/material.dart';

import '../../shared/widgets/app_scaffold.dart';

class JobsPage extends StatelessWidget {
  const JobsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Jobs',
      child: Center(child: Text('Jobs')),
    );
  }
}
