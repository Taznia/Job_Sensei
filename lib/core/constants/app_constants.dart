import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

class AppConstants {
  static const String appName = 'Job Sensei';
  static const String appVersion = '0.1.0';
  static const String accessTokenKey = 'access_token';

  /// Android emulator cannot use `localhost` — that is the emulator itself.
  /// `10.0.2.2` is the host machine where the Node API runs.
  static String get apiBaseUrl {
    var url = AppConfig.apiBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      url = url
          .replaceFirst('http://localhost', 'http://10.0.2.2')
          .replaceFirst('https://localhost', 'https://10.0.2.2')
          .replaceFirst('http://127.0.0.1', 'http://10.0.2.2')
          .replaceFirst('https://127.0.0.1', 'https://10.0.2.2');
    }
    return url;
  }
}
