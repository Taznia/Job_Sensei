import '../core/network/dio_client.dart';

class ApplicationService {
  ApplicationService({DioClient? client}) : _client = client ?? DioClient();

  final DioClient _client;

  Future<List<dynamic>> list() async {
    return await _client.get('/applications') as List<dynamic>;
  }

  Future<Map<String, dynamic>> apply({
    required String jobId,
    String? resumeId,
    String? coverLetter,
  }) async {
    return await _client.post('/applications', data: {
      'jobId': jobId,
      if (resumeId != null) 'resumeId': resumeId,
      if (coverLetter != null) 'coverLetter': coverLetter,
    }) as Map<String, dynamic>;
  }

  Future<void> updateStatus(String id, String status) {
    return _client.patch('/applications/$id', data: {'status': status});
  }
}
