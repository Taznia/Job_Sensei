import '../core/network/dio_client.dart';

class ResumeService {
  ResumeService({DioClient? client}) : _client = client ?? DioClient();

  final DioClient _client;

  Future<List<dynamic>> list() async {
    return await _client.get('/resumes') as List<dynamic>;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    return await _client.post('/resumes', data: body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> body) async {
    return await _client.patch('/resumes/$id', data: body) as Map<String, dynamic>;
  }

  Future<void> delete(String id) => _client.delete('/resumes/$id');

  Future<void> setDefault(String id) => _client.post('/resumes/$id/default');
}
