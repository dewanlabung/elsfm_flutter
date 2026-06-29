import 'package:dio/dio.dart';
import '../models/user.dart';
import '../models/app_error.dart';

/// Repository for auth swagger endpoints:
///   POST /auth/register
///   POST /auth/login  (already handled by AuthService; mirrored here for completeness)
///
/// The [AuthService] in lib/data/services/auth_service.dart covers the login +
/// token-storage flow used by the notifier. This repository provides the raw
/// register endpoint that is not yet exposed through the service layer.
class AuthRepository {
  final Dio dio;

  AuthRepository({required this.dio});

  /// POST /auth/register
  ///
  /// Returns the newly created [User]. The access token is NOT returned by the
  /// register endpoint in the swagger spec; call [login] afterwards to obtain it.
  Future<User> register({
    required String email,
    required String password,
    String tokenName = 'ELSFM Flutter App',
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'token_name': tokenName,
        },
      );
      final body = response.data!;
      final userJson = body['user'] as Map<String, dynamic>? ?? body;
      return User.fromJson(userJson);
    } catch (e) {
      throw mapToAppError(e);
    }
  }

  /// POST /auth/login — returns user + bearer token.
  ///
  /// Prefer [AuthService.loginWithEmail] for the full flow that also persists
  /// the token to secure storage and updates the auth state notifier.
  Future<({User user, String? token})> login({
    required String email,
    required String password,
    String tokenName = 'ELSFM Flutter App',
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
          'token_name': tokenName,
        },
      );
      final body = response.data!;
      final token = (body['accessToken'] ??
              body['access_token'] ??
              body['plain_text_token'] ??
              body['token']) as String?;
      final userJson = body['user'] as Map<String, dynamic>? ?? body;
      return (user: User.fromJson(userJson), token: token);
    } catch (e) {
      throw mapToAppError(e);
    }
  }
}
