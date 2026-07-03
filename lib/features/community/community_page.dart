import 'package:flutter/material.dart';

import '../../shared/widgets/app_scaffold.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Community',
      child: Center(child: Text('Community')),
    );
  }
}
