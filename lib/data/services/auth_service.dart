import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/user.dart';

class AuthService {
  final Dio dio;

  AuthService(this.dio);

  Future<({User user, String? token})> loginWithEmail(
    String email,
    String password,
  ) async {
    try {
      final loginData = {
        'email': email,
        'password': password,
        'device_name': 'Flutter App',
      };

      if (kDebugMode) {
        debugPrint('🔐 Login attempt: POST /auth/login');
        debugPrint('   BaseURL: ${dio.options.baseUrl}');
        debugPrint('   Payload: $loginData');
      }

      final response = await dio.post(
        '/auth/login',
        data: loginData,
      );

      if (kDebugMode) {
        debugPrint('✓ Login response: ${response.statusCode}');
        debugPrint('  Data: ${response.data}');
      }

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        // ELSFM API returns token as 'accessToken' or 'access_token'
        final token = data['accessToken'] ??
                      data['access_token'] ??
                      data['plain_text_token'] ??
                      data['token'] as String?;

        final userJson = (data['user'] ??
            data['data'] ??
            data['bootstrapData']?['user']) as Map<String, dynamic>;

        if (token != null) {
          dio.options.headers['Authorization'] = 'Bearer $token';
          if (kDebugMode) debugPrint('✓ Token set: Bearer ${token.substring(0, 10)}...');
        }

        return (user: User.fromJson(userJson), token: token);
      }

      final message = (response.data as Map<String, dynamic>?)?['message']
          ?? 'Unknown error (status: ${response.statusCode})';
      throw Exception('Login failed: $message');
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Login error: ${e.type}');
        debugPrint('   Status: ${e.response?.statusCode}');
        debugPrint('   Response: ${e.response?.data}');
      }
      final message = (e.response?.data as Map<String, dynamic>?)?['message']
          ?? e.message ?? 'Network error';
      throw Exception('Login failed: $message');
    }
  }

  Future<User> getCurrentUser() async {
    try {
      final response = await dio.get('/user');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final userJson = (data['user'] ?? data) as Map<String, dynamic>;
        return User.fromJson(userJson);
      }
      throw Exception('Failed to get user');
    } on DioException catch (e) {
      throw Exception('Get user error: ${e.message}');
    }
  }

  Future<void> logout() async {
    try {
      await dio.post('/auth/logout');
    } catch (_) {
      // Ignore errors on logout
    } finally {
      dio.options.headers.remove('Authorization');
    }
  }

  void setToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    dio.options.headers.remove('Authorization');
  }
}
