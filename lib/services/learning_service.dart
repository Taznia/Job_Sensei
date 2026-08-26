import '../core/network/dio_client.dart';

class LearningService {
  LearningService({DioClient? client}) : _client = client ?? DioClient();

  final DioClient _client;

  Future<Map<String, dynamic>> skillGaps({String? role}) async {
    final raw = await _client.get('/learning/skill-gaps', query: {
      if (role != null && role.isNotEmpty) 'role': role,
    });
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is List) {
      return {
        'role': role ?? '',
        'gaps': raw,
      };
    }
    return <String, dynamic>{};
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
