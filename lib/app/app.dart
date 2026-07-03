import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import 'router.dart';
import 'theme.dart';

class JobSenseiApp extends StatelessWidget {
  const JobSenseiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.light(),
      initialRoute: AppRouter.authentication,
      routes: AppRouter.routes,
    );
  }
}
