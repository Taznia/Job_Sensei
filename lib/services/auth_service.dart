import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/network/dio_client.dart';
import '../core/storage/secure_storage.dart';
import '../core/storage/shared_pref.dart';
import '../shared/models/app_user.dart';

class AuthService {
  AuthService(
      {DioClient? client, SecureStorage? storage, SharedPref? preferences})
      : _client = client ?? DioClient(),
        _storage = storage ?? SecureStorage(),
        _preferences = preferences ?? SharedPref();

  final DioClient _client;
  final SecureStorage _storage;
  final SharedPref _preferences;

  AppUser? currentUser;

  Future<AppUser?> restore() async {
    final token = await _storage.read(AppConstants.accessTokenKey);
    if (token == null || token.isEmpty) return null;
    try {
      currentUser = await me();
      await _cacheUser(currentUser!);
      return currentUser;
    } on AppException catch (error) {
      if (error.isNetwork) {
        currentUser = await _readCachedUser();
        return currentUser;
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
    String? organizationName,
  }) {
    return _authenticate('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      if (organizationName != null) 'organizationName': organizationName,
    });
  }

  Future<AppUser> login({
    required String email,
    required String password,
    required String role,
  }) {
    return _authenticate('/auth/login', {
      'email': email,
      'password': password,
      'role': role,
    });
  }

  Future<AppUser> me() async {
    final data = await _client.get('/auth/me') as Map<String, dynamic>;
    currentUser = AppUser.fromJson(data);
    return currentUser!;
  }

  Future<String?> forgotPassword(String email) async {
    final data = await _client.post(
      '/auth/forgot-password',
      data: {'email': email},
    );
    return data is Map<String, dynamic> ? data['otp'] as String? : null;
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
    await _preferences.setBool(AppConstants.sessionActiveKey, false);
    for (final key in [
      AppConstants.cachedUserIdKey,
      AppConstants.cachedUserNameKey,
      AppConstants.cachedUserEmailKey,
      AppConstants.cachedUserRoleKey,
    ]) {
      await _preferences.remove(key);
    }
  }

  Future<AppUser> _authenticate(String path, Map<String, dynamic> body) async {
    final data = await _client.post(path, data: body) as Map<String, dynamic>;
    final token = data['token'] as String;
    await _storage.write(AppConstants.accessTokenKey, token);
    currentUser = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    await _cacheUser(currentUser!);
    return currentUser!;
  }

  Future<void> _cacheUser(AppUser user) async {
    await _preferences.setBool(AppConstants.sessionActiveKey, true);
    await _preferences.setString(AppConstants.cachedUserIdKey, user.id);
    await _preferences.setString(AppConstants.cachedUserNameKey, user.name);
    await _preferences.setString(AppConstants.cachedUserEmailKey, user.email);
    await _preferences.setString(AppConstants.cachedUserRoleKey, user.role);
  }

  Future<AppUser?> _readCachedUser() async {
    final active = await _preferences.getBool(AppConstants.sessionActiveKey);
    final id = await _preferences.getString(AppConstants.cachedUserIdKey);
    final name = await _preferences.getString(AppConstants.cachedUserNameKey);
    final email = await _preferences.getString(AppConstants.cachedUserEmailKey);
    if (!active || id == null || name == null || email == null) return null;
    return AppUser(
      id: id,
      name: name,
      email: email,
      role: await _preferences.getString(AppConstants.cachedUserRoleKey) ??
          'seeker',
    );
  }
}
