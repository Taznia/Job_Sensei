import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../errors/app_exception.dart';
import '../storage/secure_storage.dart';
import 'interceptor.dart';

class DioClient {
  DioClient({SecureStorage? storage})
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConstants.apiBaseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
          ),
        ) {
    _dio.interceptors.add(AppInterceptor(storage ?? SecureStorage()));
  }

  final Dio _dio;

  Dio get instance => _dio;

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
  }) {
    return _send(() => _dio.get(path, queryParameters: query));
  }

  /// [options] is passed straight through, so a slow endpoint can raise its own
  /// timeout without changing the client-wide default. Errors are still mapped
  /// to [AppException] the same way as every other call.
  Future<dynamic> post(String path, {Object? data, Options? options}) {
    return _send(() => _dio.post(path, data: data, options: options));
  }

  Future<dynamic> patch(String path, {Object? data}) {
    return _send(() => _dio.patch(path, data: data));
  }

  Future<dynamic> put(String path, {Object? data}) {
    return _send(() => _dio.put(path, data: data));
  }

  Future<dynamic> delete(String path) {
    return _send(() => _dio.delete(path));
  }

  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      return _unwrap(response.data);
    } on DioException catch (error) {
      throw AppException(
        _messageFor(error),
        isNetwork: _isNetwork(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  dynamic _unwrap(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      if (payload['success'] == false) {
        final error = payload['error'];
        throw AppException(
          error is Map
              ? (error['message'] as String? ?? 'Request failed.')
              : 'Request failed.',
          statusCode: 400,
        );
      }
      return payload['data'] ?? payload;
    }
    return payload;
  }

  bool _isNetwork(DioException error) {
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout;
  }

  String _messageFor(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['error'] is Map) {
      return data['error']['message'] as String? ?? 'Request failed.';
    }
    if (_isNetwork(error)) {
      return 'Could not reach the Job Sensei API at ${AppConstants.apiBaseUrl}. '
          'Pass --dart-define=API_BASE_URL=... if the API is hosted separately.';
    }
    return error.message ?? 'Request failed.';
  }
}
