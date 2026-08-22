import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/injector.dart';
import 'core/config/app_config.dart';
import 'features/ai/data/sqlite/sqlite_init.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadAppEnv();
  try {
    await initSqlite();
  } catch (error) {
    debugPrint('SQLite unavailable, chat history stays in memory: $error');
    Injector.useMemoryChatHistory();
  }
  try {
    await Injector.authService().restore();
  } catch (error) {
    debugPrint('Auth restore skipped: $error');
  }
  runApp(const JobSenseiApp());
}
