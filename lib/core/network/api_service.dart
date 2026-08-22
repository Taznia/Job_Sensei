import '../network/dio_client.dart';

class ApiService {
  ApiService({DioClient? client}) : _client = client ?? DioClient();

  final DioClient _client;

  DioClient get httpClient => _client;
}
