import 'package:flutter/material.dart';

import '../../shared/widgets/app_scaffold.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Notifications',
      child: Center(child: Text('Notifications')),
    );
  }
}
