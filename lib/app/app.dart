import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class JobSenseiApp extends StatelessWidget {
  const JobSenseiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Job Sensei',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.home,
    );
  }
}
