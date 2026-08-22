import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../storage/secure_storage.dart';

class AppInterceptor extends QueuedInterceptorsWrapper {
  AppInterceptor(this._storage);

  final SecureStorage _storage;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _storage.read(AppConstants.accessTokenKey);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    } catch (error, stackTrace) {
      handler.reject(
        DioException(requestOptions: options, error: error, stackTrace: stackTrace),
      );
    }
  }
}
