import 'package:flutter/material.dart';

import '../../shared/widgets/app_scaffold.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Profile',
      child: Center(child: Text('Profile')),
    );
  }
}
