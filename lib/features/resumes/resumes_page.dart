import 'package:flutter/material.dart';

import 'presentation/screens/resume_list_screen.dart';

/// Kept as the feature's entry point so existing references (the router, the
/// shell tabs) keep working. The screen itself lives under presentation/.
class ResumesPage extends StatelessWidget {
  const ResumesPage({super.key});

  @override
  Widget build(BuildContext context) => const ResumeListScreen();
}
