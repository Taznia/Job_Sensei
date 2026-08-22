import '../core/network/dio_client.dart';

class RecruiterService {
  RecruiterService({DioClient? client}) : _client = client ?? DioClient();

  final DioClient _client;

  Future<Map<String, dynamic>> createJob(Map<String, dynamic> body) async {
    return await _client.post('/jobs', data: body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateJob(
    String id,
    Map<String, dynamic> body,
  ) async {
    return await _client.patch('/jobs/$id', data: body) as Map<String, dynamic>;
  }

  Future<void> closeJob(String id) {
    return _client.patch('/jobs/$id', data: {'status': 'closed'});
  }
}
