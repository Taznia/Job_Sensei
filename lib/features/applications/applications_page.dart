import 'package:flutter/material.dart';

import '../../shared/widgets/app_scaffold.dart';

class ApplicationsPage extends StatelessWidget {
  const ApplicationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Applications',
      child: Center(child: Text('Applications')),
    );
  }
}
