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
        'token_name': 'ELSFM Flutter App',
      };

      if (kDebugMode) {
        debugPrint('🔐 Login attempt: POST ${dio.options.baseUrl}/auth/login');
      }

      final response = await dio.post(
        '/auth/login',
        data: loginData,
        options: Options(
          contentType: 'application/json',
        ),
      );

      if (kDebugMode) {
        debugPrint('✓ Login response: ${response.statusCode}');
      }

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        // Try to extract token from response (some endpoints return it)
        final token = (data['accessToken'] ??
                      data['access_token'] ??
                      data['plain_text_token'] ??
                      data['token']) as String?;

        if (token != null) {
          dio.options.headers['Authorization'] = 'Bearer $token';
          if (kDebugMode) debugPrint('✓ Token set: Bearer ${token.substring(0, 10)}...');
        }

        // Extract user from the bootstrap response
        // The login endpoint returns user data in the response
        final userJson = data['user'] as Map<String, dynamic>?;
        if (userJson == null) {
          throw Exception('Login failed: No user data in response');
        }

        final user = User.fromJson(userJson);
        if (kDebugMode) {
          debugPrint('✓ Login successful: user=${user.email}');
        }

        return (user: user, token: token);
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

  Future<({User user, String? token})> loginWithGoogle(
    String idToken,
    String email,
  ) async {
    try {
      final loginData = {
        'id_token': idToken,
        'email': email,
        'provider': 'google',
        'token_name': 'ELSFM Flutter App',
      };

      if (kDebugMode) {
        debugPrint('🔐 Google login attempt: POST /auth/google');
        debugPrint('   Email: $email');
      }

      final response = await dio.post(
        '/auth/google',
        data: loginData,
        options: Options(contentType: 'application/json'),
      );

      if (kDebugMode) {
        debugPrint('✓ Google login response: ${response.statusCode}');
      }

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        final token = (data['accessToken'] ??
                      data['access_token'] ??
                      data['plain_text_token'] ??
                      data['token']) as String?;

        if (token != null) {
          dio.options.headers['Authorization'] = 'Bearer $token';
        }

        final userJson = data['user'] as Map<String, dynamic>?;
        if (userJson == null) {
          throw Exception('Google login failed: No user data in response');
        }

        final user = User.fromJson(userJson);
        if (kDebugMode) {
          debugPrint('✓ Google login successful: user=${user.email}');
        }

        return (user: user, token: token);
      }

      throw Exception('Google login failed: Invalid response');
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Google login error: ${e.response?.statusCode}');
      }
      throw Exception('Google login failed: ${e.message}');
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
