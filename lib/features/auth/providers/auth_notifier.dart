import 'dart:convert';
import 'package:dio/dio.dart' show DioException, Dio, BaseOptions;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/providers/http_client_provider.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/models/user.dart';
import '../models/auth_state.dart';
import '../services/biometric_auth_service.dart';

const _tokenKey = 'auth_token';
const _cachedUserKey = 'cached_user';

class AuthNotifier extends StateNotifier<AuthStateData> {
  final AuthService authService;
  final FlutterSecureStorage secureStorage;
  late final BiometricAuthService biometricService;

  AuthNotifier({
    required this.authService,
    required this.secureStorage,
  }) : super(AuthStateData.unauthenticated()) {
    biometricService = BiometricAuthService(secureStorage);
    _initAuth();
  }

  Future<void> _cacheUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedUserKey, jsonEncode(user.toJson()));
    } catch (_) {}
  }

  Future<User?> _getCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cachedUserKey);
      if (raw == null) return null;
      return User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedUserKey);
    } catch (_) {}
  }

  Future<void> _initAuth() async {
    state = state.copyWith(state: AuthState.authenticating);

    // 1. Try biometric login first if enabled
    try {
      final biometricToken = await biometricService.authenticateWithBiometric();
      if (biometricToken != null) {
        authService.setToken(biometricToken);
        final user = await authService.getCurrentUser();
        await _cacheUser(user);
        state = AuthStateData.authenticated(user);
        return;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Biometric init error: $e');
    }

    // 2. Try saved token
    final savedToken = await secureStorage.read(key: _tokenKey);
    if (savedToken != null) {
      authService.setToken(savedToken);
      try {
        final user = await authService.getCurrentUser();
        await _cacheUser(user);
        state = AuthStateData.authenticated(user);
        return;
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) {
          // Token invalid — force re-login
          await secureStorage.delete(key: _tokenKey);
          await _clearCachedUser();
          authService.clearToken();
        } else {
          // Network error — restore from cache so user stays logged in offline
          final cached = await _getCachedUser();
          if (cached != null) {
            state = AuthStateData.authenticated(cached);
            return;
          }
        }
      } catch (_) {
        // Any other error — try cache
        final cached = await _getCachedUser();
        if (cached != null) {
          state = AuthStateData.authenticated(cached);
          return;
        }
      }
    }

    state = AuthStateData.unauthenticated();
  }

  Future<void> loginWithEmail(String email, String password) async {
    try {
      state = state.copyWith(state: AuthState.authenticating);
      final result = await authService.loginWithEmail(email, password);
      if (result.token != null) {
        await secureStorage.write(key: _tokenKey, value: result.token);
      }
      await _cacheUser(result.user);
      state = AuthStateData.authenticated(result.user);
    } catch (e) {
      state = AuthStateData.error(e.toString());
    }
  }

  /// Login with a token obtained from WebView-based social OAuth callback.
  Future<void> loginWithSocialToken(String token) async {
    try {
      state = state.copyWith(state: AuthState.authenticating);
      authService.setToken(token);
      final user = await authService.getCurrentUser();
      await secureStorage.write(key: _tokenKey, value: token);
      await _cacheUser(user);
      state = AuthStateData.authenticated(user);
    } catch (e) {
      authService.clearToken();
      state = AuthStateData.error('Social login failed: ${e.toString()}');
    }
  }

  /// Called after WebView social OAuth when no token in URL — rely on session cookie.
  Future<void> loginWithSession() async {
    try {
      state = state.copyWith(state: AuthState.authenticating);
      final result = await authService.loginWithSession();
      if (result.token != null) {
        await secureStorage.write(key: _tokenKey, value: result.token!);
        authService.setToken(result.token!);
      }
      await _cacheUser(result.user);
      state = AuthStateData.authenticated(result.user);
    } catch (e) {
      state = AuthStateData.error('Social login failed: ${e.toString()}');
    }
  }

  Future<void> register(
    String name,
    String email,
    String password,
    String passwordConfirmation,
  ) async {
    try {
      state = state.copyWith(state: AuthState.authenticating);
      final result = await authService.register(name, email, password, passwordConfirmation);
      if (result.token != null) {
        await secureStorage.write(key: _tokenKey, value: result.token);
      }
      await _cacheUser(result.user);
      state = AuthStateData.authenticated(result.user);
    } catch (e) {
      state = AuthStateData.error(e.toString());
    }
  }

  Future<String> forgotPassword(String email) async {
    return authService.forgotPassword(email);
  }

  Future<void> updateProfile({String? name, String? email}) async {
    final userId = state.user?.id;
    if (userId == null) throw Exception('Not authenticated');
    final user = await authService.updateProfile(
        userId: userId, name: name, email: email);
    await _cacheUser(user);
    state = AuthStateData.authenticated(user);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    await authService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmation: confirmation,
    );
  }

  Future<void> logout() async {
    try {
      await authService.logout();
    } catch (_) {}
    await secureStorage.delete(key: _tokenKey);
    await _clearCachedUser();
    try {
      await biometricService.disableBiometric();
    } catch (_) {}
    state = AuthStateData.unauthenticated();
  }

  Future<void> enableBiometricLogin() async {
    try {
      final token = await secureStorage.read(key: _tokenKey);
      if (token != null) await biometricService.enableBiometric(token);
    } catch (_) {}
  }

  Future<void> disableBiometricLogin() async {
    try {
      await biometricService.disableBiometric();
    } catch (_) {}
  }
}

final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());

final authServiceProvider = Provider((ref) {
  try {
    return ref.watch(dioProvider).when(
      data: (dio) => AuthService(dio),
      loading: () => AuthService(Dio(BaseOptions(baseUrl: 'https://www.elsfm.com/api/v1'))),
      error: (err, st) => throw err,
    );
  } catch (e) {
    return AuthService(Dio(BaseOptions(baseUrl: 'https://www.elsfm.com/api/v1')));
  }
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthStateData>((ref) {
  final authService = ref.watch(authServiceProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthNotifier(authService: authService, secureStorage: secureStorage);
});
