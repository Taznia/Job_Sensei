import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

class AppConstants {
  static const String appName = 'Job Sensei';
  static const String appVersion = '0.1.0';
  static const String accessTokenKey = 'access_token';
  static const String sessionActiveKey = 'session_active';
  static const String cachedUserIdKey = 'cached_user_id';
  static const String cachedUserNameKey = 'cached_user_name';
  static const String cachedUserEmailKey = 'cached_user_email';
  static const String cachedUserRoleKey = 'cached_user_role';

  /// Android emulator cannot use `localhost` — that is the emulator itself.
  /// `10.0.2.2` is the host machine where the Node API runs.
  ///
  /// The rewrite only applies to the built-in fallback. An explicit
  /// `--dart-define=API_BASE_URL=...` (or `.env`) is used verbatim, because
  /// `10.0.2.2` is wrong on a physical handset: there you either reach the
  /// laptop over the LAN, or map the port across USB with
  /// `adb reverse tcp:1190 tcp:1190` and keep using 127.0.0.1.
  static String get apiBaseUrl {
    var url = AppConfig.apiBaseUrl;
    if (AppConfig.hasCustomApiUrl) return url;
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
