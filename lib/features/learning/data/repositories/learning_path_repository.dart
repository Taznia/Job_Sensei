import '../../../../core/network/dio_client.dart';
import '../../../../shared/models/learning_path_models.dart';

abstract interface class LearningPathRepository {
  Future<List<StructuredLearningPath>> pathsForSkills(List<String> skills);
  Future<StructuredLearningPath> pathDetails(String pathId);
}

class ApiLearningPathRepository implements LearningPathRepository {
  ApiLearningPathRepository({DioClient? client})
      : _client = client ?? DioClient();

  final DioClient _client;

  @override
  Future<List<StructuredLearningPath>> pathsForSkills(
    List<String> skills,
  ) async {
    final paths = <StructuredLearningPath>[];
    for (final skill in skills) {
      final response = await _client.get(
        '/learning/skills/${Uri.encodeComponent(skill)}/paths',
      ) as Map<String, dynamic>;
      for (final item in response['paths'] as List<dynamic>? ?? const []) {
        final summary = Map<String, dynamic>.from(item as Map);
        // Summary responses contain no lessons. Details are loaded on tap.
        paths.add(StructuredLearningPath.fromJson(summary));
      }
    }
    return paths;
  }

  @override
  Future<StructuredLearningPath> pathDetails(String pathId) async {
    final response =
        await _client.get('/learning/paths/$pathId') as Map<String, dynamic>;
    return StructuredLearningPath.fromJson(response);
  }
}
