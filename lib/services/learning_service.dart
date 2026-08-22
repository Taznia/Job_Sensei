import '../core/network/dio_client.dart';

class LearningService {
  LearningService({DioClient? client}) : _client = client ?? DioClient();

  final DioClient _client;

  Future<Map<String, dynamic>> skillGaps({String? role}) async {
    return await _client.get('/learning/skill-gaps', query: {
      if (role != null) 'role': role,
    }) as Map<String, dynamic>;
  }

  Future<List<dynamic>> resources({String? skill}) async {
    return await _client.get('/learning/resources', query: {
      if (skill != null) 'skill': skill,
    }) as List<dynamic>;
  }

  Future<void> updateSkills(List<Map<String, dynamic>> skills) {
    return _client.put('/learning/skills', data: {'skills': skills});
  }
}
