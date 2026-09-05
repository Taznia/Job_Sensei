import 'package:flutter/material.dart';

import 'presentation/screens/application_tracker_screen.dart';

/// Kept as the feature's entry point so existing references (the router, the
/// shell tabs) keep working. The screen itself lives under presentation/.
class ApplicationsPage extends StatelessWidget {
  const ApplicationsPage({super.key});

  @override
  Widget build(BuildContext context) => const ApplicationTrackerScreen();
}
