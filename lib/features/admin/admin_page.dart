import 'package:flutter/material.dart';

import '../../shared/widgets/app_scaffold.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Admin',
      child: Center(child: Text('Admin')),
    );
  }
}
