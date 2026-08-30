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

  /// Module 3 search. Distinct from [list], which hits the simpler shared
  /// listing; this one carries the full filter set and relevance ranking.
  Future<Map<String, dynamic>> search(Map<String, dynamic> query) async {
    return await _client.get('/jobs/search', query: query)
        as Map<String, dynamic>;
  }

  /// Distinct values that actually exist, for the filter sheet.
  Future<Map<String, dynamic>> filterOptions() async {
    return await _client.get('/jobs/search/filters') as Map<String, dynamic>;
  }

  /// Module 4 match score for one job against the signed-in user.
  Future<Map<String, dynamic>> match(String id, {String? resumeId}) async {
    return await _client.get('/jobs/$id/match', query: {
      if (resumeId != null) 'resumeId': resumeId,
    }) as Map<String, dynamic>;
  }

  /// The best-fitting jobs for the signed-in user, ranked.
  Future<Map<String, dynamic>> topMatches({int limit = 5}) async {
    return await _client.get('/jobs/match/top', query: {'limit': limit})
        as Map<String, dynamic>;
  }
}
