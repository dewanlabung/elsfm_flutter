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

  /// BeMusic social auth: pass the Google access token to the callback endpoint.
  /// SocialAuthController::loginCallback() calls
  ///   Socialite::driver('google')->userFromToken($tokenFromApi)
  /// and returns MobileBootstrapData (same shape as email login response).
  Future<({User user, String? token})> loginWithGoogle(
    String accessToken,
  ) async {
    try {
      if (kDebugMode) {
        debugPrint('🔐 Google login: GET /auth/social/google/callback');
      }

      final response = await dio.get(
        '/auth/social/google/callback',
        queryParameters: {
          'tokenFromApi': accessToken,
          'token_name': 'ELSFM Flutter App',
        },
      );

      if (kDebugMode) {
        debugPrint('✓ Google social callback: ${response.statusCode}');
      }

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        // MobileBootstrapData shape — token may be in user or top-level
        final userBlock = data['user'] as Map<String, dynamic>?;
        final token = (userBlock?['access_token'] ??
                      userBlock?['plain_text_token'] ??
                      data['access_token'] ??
                      data['plain_text_token'] ??
                      data['token']) as String?;

        final userJson = (data['user'] ?? data) as Map<String, dynamic>?;
        if (userJson == null) {
          throw Exception('Google login failed: No user data in response');
        }

        if (token != null) {
          dio.options.headers['Authorization'] = 'Bearer $token';
        }

        final user = User.fromJson(userJson);
        if (kDebugMode) debugPrint('✓ Google login OK: ${user.email}');
        return (user: user, token: token);
      }

      throw Exception('Google login failed: status ${response.statusCode}');
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Google login error: ${e.response?.statusCode}');
        debugPrint('   Body: ${e.response?.data}');
      }
      final msg = (e.response?.data as Map?)?['message'] ?? e.message ?? 'Network error';
      throw Exception('Google login failed: $msg');
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
