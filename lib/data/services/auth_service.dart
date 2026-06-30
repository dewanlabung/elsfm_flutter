import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/user.dart';

class AuthService {
  final Dio dio;

  AuthService(this.dio);

  String? _extractToken(Map<String, dynamic> data) =>
      (data['accessToken'] ?? data['access_token'] ?? data['plain_text_token'] ?? data['token'])
          as String?;

  Future<({User user, String? token})> loginWithEmail(
    String email,
    String password,
  ) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: {'email': email, 'password': password, 'token_name': 'ELSFM Flutter App'},
        options: Options(contentType: 'application/json'),
      );

      if (kDebugMode) debugPrint('Login response: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final token = _extractToken(data);
        if (token != null) dio.options.headers['Authorization'] = 'Bearer $token';

        final userJson = data['user'] as Map<String, dynamic>?;
        if (userJson == null) throw Exception('Login failed: No user data in response');
        return (user: User.fromJson(userJson), token: token);
      }

      final message = (response.data as Map<String, dynamic>?)?['message']
          ?? 'Login failed (status: ${response.statusCode})';
      throw Exception(message);
    } on DioException catch (e) {
      final message = (e.response?.data as Map<String, dynamic>?)?['message']
          ?? e.message ?? 'Network error';
      throw Exception(message);
    }
  }

  Future<({User user, String? token})> register(
    String name,
    String email,
    String password,
    String passwordConfirmation,
  ) async {
    try {
      final response = await dio.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'token_name': 'ELSFM Flutter App',
        },
        options: Options(contentType: 'application/json'),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final token = _extractToken(data);
        if (token != null) dio.options.headers['Authorization'] = 'Bearer $token';

        final userJson = data['user'] as Map<String, dynamic>?;
        if (userJson == null) throw Exception('Registration failed: No user data');
        return (user: User.fromJson(userJson), token: token);
      }

      final message = (response.data as Map<String, dynamic>?)?['message']
          ?? 'Registration failed (status: ${response.statusCode})';
      throw Exception(message);
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = e.message ?? 'Network error';
      if (data is Map) {
        // Laravel validation errors come as {errors: {field: [msg]}}
        final errors = data['errors'] as Map?;
        if (errors != null) {
          message = errors.values
              .expand((v) => v is List ? v : [v])
              .join('\n');
        } else {
          message = data['message'] as String? ?? message;
        }
      }
      throw Exception(message);
    }
  }

  Future<String> forgotPassword(String email) async {
    try {
      final response = await dio.post(
        '/auth/password/email',
        data: {'email': email},
        options: Options(contentType: 'application/json'),
      );
      final data = response.data as Map<String, dynamic>?;
      return data?['message'] as String? ?? 'Password reset email sent.';
    } on DioException catch (e) {
      final message = (e.response?.data as Map<String, dynamic>?)?['message']
          ?? 'Failed to send reset email';
      throw Exception(message);
    }
  }

  /// Exchange a Google OAuth token for a BeMusic auth token.
  /// BeMusic's Socialite backend verifies the token and returns a user + API token.
  Future<({User user, String? token})> loginWithGoogleToken({
    String? accessToken,
    String? idToken,
  }) async {
    if (accessToken == null && idToken == null) {
      throw Exception('No Google token provided');
    }
    try {
      final response = await dio.post(
        '/auth/social/google',
        data: <String, dynamic>{
          if (accessToken != null) 'access_token': accessToken,
          if (idToken != null) 'id_token': idToken,
          'provider': 'google',
        },
        options: Options(contentType: 'application/json'),
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final token = _extractToken(data);
        if (token != null) dio.options.headers['Authorization'] = 'Bearer $token';
        final userJson = data['user'] as Map<String, dynamic>?;
        if (userJson != null) return (user: User.fromJson(userJson), token: token);
      }
      throw Exception('Unexpected response from social login');
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['message'] as String? ??
          e.message ??
          'Google login failed';
      throw Exception(msg);
    }
  }

  /// Get current user using existing session/cookie (after WebView social OAuth).
  Future<({User user, String? token})> loginWithSession() async {
    try {
      // BeMusic may return a csrf-token endpoint or we just try /user
      final response = await dio.get('/user');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final userJson = (data['user'] ?? data) as Map<String, dynamic>;
        return (user: User.fromJson(userJson), token: null);
      }
      throw Exception('Session login failed');
    } on DioException catch (e) {
      throw Exception('Session login failed: ${e.message}');
    }
  }

  Future<User> getCurrentUser() async {
    final response = await dio.get('/user');
    if (response.statusCode == 200 && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      final userJson = (data['user'] ?? data) as Map<String, dynamic>;
      return User.fromJson(userJson);
    }
    throw Exception('Failed to get user (status: ${response.statusCode})');
  }

  Future<User> updateProfile({
    required int userId,
    String? name,
    String? email,
  }) async {
    try {
      final response = await dio.put(
        '/users/$userId',
        data: {
          if (name != null) 'name': name,
          if (email != null) 'email': email,
        },
        options: Options(contentType: 'application/json'),
      );
      final data = response.data as Map<String, dynamic>;
      final userJson = (data['user'] ?? data) as Map<String, dynamic>;
      return User.fromJson(userJson);
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['message'] as String?
          ?? e.message
          ?? 'Failed to update profile';
      throw Exception(msg);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    try {
      await dio.post(
        '/auth/change-password',
        data: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': confirmation,
        },
        options: Options(contentType: 'application/json'),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg = e.message ?? 'Failed to change password';
      if (data is Map) {
        final errors = data['errors'] as Map?;
        if (errors != null) {
          msg = errors.values.expand((v) => v is List ? v : [v]).join('\n');
        } else {
          msg = data['message'] as String? ?? msg;
        }
      }
      throw Exception(msg);
    }
  }

  Future<void> logout() async {
    try {
      await dio.post('/auth/logout');
    } catch (_) {}
    dio.options.headers.remove('Authorization');
  }

  void setToken(String token) {
    final preview = token.length > 20 ? '${token.substring(0, 20)}...' : token;
    debugPrint('[AuthService] Setting token: $preview (${token.length} chars)');
    dio.options.headers['Authorization'] = 'Bearer $token';
    debugPrint('[AuthService] Authorization header set: ${dio.options.headers['Authorization'] != null}');
  }

  void clearToken() {
    debugPrint('[AuthService] Clearing token');
    dio.options.headers.remove('Authorization');
    debugPrint('[AuthService] Authorization header cleared');
  }
}
