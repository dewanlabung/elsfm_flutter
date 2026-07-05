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
import '../services/google_sign_in_service.dart';

const _tokenKey = 'auth_token';
const _cachedUserKey = 'cached_user';

class AuthNotifier extends Notifier<AuthStateData> {
  // Not `late final` — Notifier.build() can run again on the same instance
  // whenever a watched dependency (authServiceProvider / dioProvider) changes,
  // and reassigning a `late final` field throws LateInitializationError.
  late AuthService _authService;
  late FlutterSecureStorage _secureStorage;

  @override
  AuthStateData build() {
    _authService = ref.watch(authServiceProvider);
    _secureStorage = ref.watch(secureStorageProvider);
    // Kick off async init without blocking the synchronous build.
    Future.microtask(_initAuth);
    return AuthStateData.unauthenticated();
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

    final savedToken = await _secureStorage.read(key: _tokenKey);
    if (savedToken != null) {
      _authService.setToken(savedToken);
      try {
        final user = await _authService.getCurrentUser();
        await _cacheUser(user);
        state = AuthStateData.authenticated(user);
        return;
      } on DioException catch (e) {
        // Only clear token on 401 Unauthorized — not on network errors.
        if (e.response?.statusCode == 401) {
          await _secureStorage.delete(key: _tokenKey);
          await _clearCachedUser();
          _authService.clearToken();
        } else {
          if (kDebugMode) debugPrint('Network error during auth init: $e');
          // Network error — restore from cache so the user stays logged in offline.
          final cached = await _getCachedUser();
          if (cached != null) {
            state = AuthStateData.authenticated(cached);
            return;
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Auth init error: $e');
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
      final result = await _authService.loginWithEmail(email, password);
      if (result.token != null) {
        await _secureStorage.write(key: _tokenKey, value: result.token);
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
      _authService.setToken(token);
      final user = await _authService.getCurrentUser();
      await _secureStorage.write(key: _tokenKey, value: token);
      await _cacheUser(user);
      state = AuthStateData.authenticated(user);
    } catch (e) {
      _authService.clearToken();
      state = AuthStateData.error('Social login failed: ${e.toString()}');
    }
  }

  /// Sign in with the device's Google account (native account picker).
  /// Returns false if native sign-in fails so the caller can fall back to WebView.
  Future<bool> loginWithGoogle() async {
    try {
      state = state.copyWith(state: AuthState.authenticating);
      final service = GoogleSignInService();
      final googleResult = await service.signInWithGoogle();

      final result = await _authService.loginWithGoogleToken(
        accessToken: googleResult.accessToken,
        idToken: googleResult.idToken,
      );

      if (result.token != null) {
        await _secureStorage.write(key: _tokenKey, value: result.token!);
      }
      await _cacheUser(result.user);
      state = AuthStateData.authenticated(result.user);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Native Google Sign-In failed: $e');
      state = AuthStateData.unauthenticated();
      return false;
    }
  }

  /// Called after WebView social OAuth when no token in URL — rely on session cookie.
  Future<void> loginWithSession() async {
    try {
      state = state.copyWith(state: AuthState.authenticating);
      final result = await _authService.loginWithSession();
      if (result.token != null) {
        await _secureStorage.write(key: _tokenKey, value: result.token!);
        _authService.setToken(result.token!);
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
      final result = await _authService.register(
          name, email, password, passwordConfirmation);
      if (result.token != null) {
        await _secureStorage.write(key: _tokenKey, value: result.token);
      }
      await _cacheUser(result.user);
      state = AuthStateData.authenticated(result.user);
    } catch (e) {
      state = AuthStateData.error(e.toString());
    }
  }

  Future<String> forgotPassword(String email) async {
    return _authService.forgotPassword(email);
  }

  Future<void> updateProfile({String? name, String? email}) async {
    final userId = state.user?.id;
    if (userId == null) throw Exception('Not authenticated');
    final user = await _authService.updateProfile(
        userId: userId, name: name, email: email);
    await _cacheUser(user);
    state = AuthStateData.authenticated(user);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    await _authService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmation: confirmation,
    );
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (_) {}
    await _secureStorage.delete(key: _tokenKey);
    await _clearCachedUser();
    state = AuthStateData.unauthenticated();
  }
}

final secureStorageProvider = Provider((ref) {
  return const FlutterSecureStorage();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return ref.watch(dioProvider).when(
    data: (dio) => AuthService(dio),
    loading: () =>
        AuthService(Dio(BaseOptions(baseUrl: 'https://www.elsfm.com/api/v1'))),
    error: (_, __) =>
        AuthService(Dio(BaseOptions(baseUrl: 'https://www.elsfm.com/api/v1'))),
  );
});

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthStateData>(AuthNotifier.new);
