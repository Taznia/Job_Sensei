import '../core/network/dio_client.dart';

class JobService {
  JobService({DioClient? client}) : _client = client ?? DioClient();

  final DioClient _client;

  Future<Map<String, dynamic>> list({
    String? query,
    String? location,
    String? type,
    int page = 1,
  }) async {
    return await _client.get('/jobs', query: {
      if (query != null && query.isNotEmpty) 'q': query,
      if (location != null && location.isNotEmpty) 'location': location,
      if (type != null && type.isNotEmpty) 'type': type,
      'page': page,
    }) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> recommended() async {
    return {'items': await _client.get('/jobs/recommended')};
  }

  Future<Map<String, dynamic>> getById(String id) async {
    return await _client.get('/jobs/$id') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> selectedJobSkillGap(String id) async {
    return await _client.post('/jobs/$id/skill-gap') as Map<String, dynamic>;
  }

  Future<void> save(String id) => _client.post('/jobs/$id/save');

  Future<void> unsave(String id) => _client.delete('/jobs/$id/save');
}
