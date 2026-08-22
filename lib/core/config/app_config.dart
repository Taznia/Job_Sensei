import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Compile-time `--dart-define` values override `.env` in the Flutter project root.
///
/// Chat uses [geminiApiKey] on-device. The Job Sensei API is separate ([apiBaseUrl]).
abstract final class AppConfig {
  static const _definedApiUrl = String.fromEnvironment('API_BASE_URL');
  static const _definedGeminiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _definedGeminiModel = String.fromEnvironment('GEMINI_MODEL');
  static const _localApiFallback = String.fromEnvironment(
    'LOCAL_API_BASE_URL',
    defaultValue: 'http://localhost:5000/api',
  );

  static String _env(String key) => (dotenv.isInitialized ? dotenv.env[key] : null)?.trim() ?? '';

  static String get geminiApiKey {
    if (_definedGeminiKey.trim().isNotEmpty) return _definedGeminiKey.trim();
    return _env('GEMINI_API_KEY');
  }

  static bool get isGeminiConfigured => geminiApiKey.isNotEmpty;

  static String get geminiModel {
    if (_definedGeminiModel.trim().isNotEmpty) return _definedGeminiModel.trim();
    final fromFile = _env('GEMINI_MODEL');
    if (fromFile.isNotEmpty) return fromFile;
    return 'gemini-3.5-flash';
  }

  static bool get hasCustomApiUrl =>
      _definedApiUrl.trim().isNotEmpty || _env('API_BASE_URL').isNotEmpty;

  static String get apiBaseUrl {
    final fromDefine = _definedApiUrl.trim();
    final fromFile = _env('API_BASE_URL');
    final raw = fromDefine.isNotEmpty
        ? fromDefine
        : fromFile.isNotEmpty
            ? fromFile
            : _localApiFallback.trim();
    return normalizeApiBaseUrl(raw);
  }

  static String normalizeApiBaseUrl(String raw) {
    var url = raw.trim();
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (url.endsWith('/api')) {
      return url;
    }
    return '$url/api';
  }
}

Future<void> loadAppEnv() async {
  try {
    await dotenv.load(fileName: '.env', isOptional: true);
  } catch (_) {}
  if (!dotenv.isInitialized) {
    try {
      await dotenv.load(fileName: '.env.example', isOptional: true);
    } catch (_) {}
  }
  if (!dotenv.isInitialized) {
    dotenv.testLoad(fileInput: '');
  }
}
