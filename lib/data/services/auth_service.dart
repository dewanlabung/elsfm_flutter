import 'package:dio/dio.dart';
import '../models/user.dart';

class AuthService {
  final Dio dio;

  AuthService(this.dio);

  Future<User> loginWithEmail(String email, String password) async {
    try {
      final response = await dio.post(
        '/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return User.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw Exception('Login failed: ${response.data['message'] ?? 'Unknown error'}');
    } on DioException catch (e) {
      throw Exception('Login error: ${e.message}');
    }
  }

  Future<User> getCurrentUser() async {
    try {
      final response = await dio.get('/user');
      if (response.statusCode == 200 && response.data != null) {
        return User.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to get user');
    } on DioException catch (e) {
      throw Exception('Get user error: ${e.message}');
    }
  }

  Future<void> logout() async {
    try {
      await dio.post('/logout');
    } catch (e) {
      // Ignore errors on logout
    }
  }
}
