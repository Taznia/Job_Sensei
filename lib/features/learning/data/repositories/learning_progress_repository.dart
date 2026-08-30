import '../../../../core/network/dio_client.dart';
import '../../../../shared/models/learning_progress_models.dart';

abstract interface class LearningProgressRepository {
  Future<List<LearningProgress>> forPath(String pathId);
  Future<LearningProgress> start(
      {required String pathId, required String resourceId});
  Future<LearningProgress> complete(
      {required String pathId, required String resourceId});
}

class ApiLearningProgressRepository implements LearningProgressRepository {
  ApiLearningProgressRepository({DioClient? client})
      : _client = client ?? DioClient();
  final DioClient _client;

  @override
  Future<List<LearningProgress>> forPath(String pathId) async {
    final data =
        await _client.get('/learning/paths/$pathId/progress') as List<dynamic>;
    return data.map(_fromJson).toList();
  }

  @override
  Future<LearningProgress> start(
          {required String pathId, required String resourceId}) async =>
      _fromJson(await _client.post('/learning/resources/$resourceId/start',
          data: {'learningPathId': pathId}) as Map<String, dynamic>);

  @override
  Future<LearningProgress> complete(
          {required String pathId, required String resourceId}) async =>
      _fromJson(await _client.post('/learning/resources/$resourceId/complete',
          data: {'learningPathId': pathId}) as Map<String, dynamic>);

  LearningProgress _fromJson(dynamic json) => LearningProgress(
      resourceId: json['resourceId'] as String,
      status: json['status'] as String);
}

class InMemoryLearningProgressRepository implements LearningProgressRepository {
  final Map<String, LearningProgress> _items = {};

  @override
  Future<List<LearningProgress>> forPath(String pathId) async =>
      _items.values.toList();

  @override
  Future<LearningProgress> start(
          {required String pathId, required String resourceId}) async =>
      _items[resourceId] ??=
          LearningProgress(resourceId: resourceId, status: 'in_progress');

  @override
  Future<LearningProgress> complete(
      {required String pathId, required String resourceId}) async {
    final item = LearningProgress(resourceId: resourceId, status: 'completed');
    _items[resourceId] = item;
    return item;
  }
}
