import 'dio_client.dart';

class ApiService {
  ApiService({DioClient? client}) : _client = client ?? DioClient();

  final DioClient _client;

  dynamic get httpClient => _client.instance;
}
