import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/network/dio_client.dart';
import '../core/storage/secure_storage.dart';
import '../shared/models/app_user.dart';

class AuthService {
  AuthService({DioClient? client, SecureStorage? storage})
      : _client = client ?? DioClient(),
        _storage = storage ?? SecureStorage();

  final DioClient _client;
  final SecureStorage _storage;

  AppUser? currentUser;

  Future<AppUser?> restore() async {
    final token = await _storage.read(AppConstants.accessTokenKey);
    if (token == null || token.isEmpty) return null;
    try {
      currentUser = await me();
      return currentUser;
    } on AppException catch (error) {
      if (error.isNetwork) {
        return null;
      }
      await logout();
      return null;
    } catch (_) {
      await logout();
      return null;
    }
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    String role = 'seeker',
  }) {
    return _authenticate('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    });
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) {
    return _authenticate('/auth/login', {
      'email': email,
      'password': password,
    });
  }

  Future<AppUser> me() async {
    final data = await _client.get('/auth/me') as Map<String, dynamic>;
    currentUser = AppUser.fromJson(data);
    return currentUser!;
  }

  Future<void> forgotPassword(String email) {
    return _client.post('/auth/forgot-password', data: {'email': email});
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) {
    return _client.post('/auth/reset-password', data: {
      'email': email,
      'otp': otp,
      'password': password,
    });
  }

  Future<void> logout() async {
    currentUser = null;
    await _storage.delete(AppConstants.accessTokenKey);
  }

  Future<AppUser> _authenticate(String path, Map<String, dynamic> body) async {
    final data = await _client.post(path, data: body) as Map<String, dynamic>;
    final token = data['token'] as String;
    await _storage.write(AppConstants.accessTokenKey, token);
    currentUser = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    return currentUser!;
  }
}
