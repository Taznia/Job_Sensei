import 'package:dio/dio.dart';

class DioClient {
  DioClient() : _dio = Dio(BaseOptions());

  final Dio _dio;

  Dio get instance => _dio;
}
