import '../core/network/dio_client.dart';

class RewardService {
  RewardService({DioClient? client}) : _client = client ?? DioClient();

  final DioClient _client;

  Future<Map<String, dynamic>> me() async {
    return await _client.get('/rewards/me') as Map<String, dynamic>;
  }
}
