import '../core/network/dio_client.dart';

class NotificationService {
  NotificationService({DioClient? client}) : _client = client ?? DioClient();

  final DioClient _client;

  Future<List<dynamic>> list() async {
    return await _client.get('/notifications') as List<dynamic>;
  }

  Future<void> markRead(String id) => _client.patch('/notifications/$id/read');

  Future<void> markAllRead() => _client.patch('/notifications/read-all');
}
