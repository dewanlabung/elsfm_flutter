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
import '../services/google_sign_in_service.dart';

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
    debugPrint('[Auth] Starting _initAuth()');
    state = state.copyWith(state: AuthState.authenticating);

    // 1. Try biometric login first if enabled
    try {
      debugPrint('[Auth] Attempting biometric authentication...');
      final biometricToken = await biometricService.authenticateWithBiometric();
      if (biometricToken != null) {
        debugPrint('[Auth] Biometric token obtained, setting in authService');
        authService.setToken(biometricToken);
        final user = await authService.getCurrentUser();
        await _cacheUser(user);
        debugPrint('[Auth] Biometric login successful: ${user.email}');
        state = AuthStateData.authenticated(user);
        return;
      }
      debugPrint('[Auth] No biometric token available');
    } catch (e) {
      debugPrint('[Auth] ❌ Biometric init error: $e');
    }

    // 2. Try saved token
    debugPrint('[Auth] Reading token from secure storage...');
    final savedToken = await secureStorage.read(key: _tokenKey);
    if (savedToken != null && savedToken.isNotEmpty) {
      debugPrint('[Auth] ✅ Token found in secure storage (${savedToken.length} chars)');
      debugPrint('[Auth] Setting token in authService...');
      authService.setToken(savedToken);

      // Try to get fresh user data, but don't fail if network is down
      try {
        debugPrint('[Auth] Verifying token with API...');
        final user = await authService.getCurrentUser();
        await _cacheUser(user);
        debugPrint('[Auth] ✅ Token valid! User authenticated: ${user.email}');
        state = AuthStateData.authenticated(user);
        return;
      } on DioException catch (e) {
        debugPrint('[Auth] ❌ API call failed: ${e.response?.statusCode} - ${e.message}');
        if (e.response?.statusCode == 401) {
          debugPrint('[Auth] Token expired (401), clearing from storage');
          await secureStorage.delete(key: _tokenKey);
          await _clearCachedUser();
          authService.clearToken();
        } else {
          debugPrint('[Auth] Network error, restoring from cache...');
          final cached = await _getCachedUser();
          if (cached != null) {
            debugPrint('[Auth] ✅ Restored user from cache: ${cached.email}');
            debugPrint('[Auth] ℹ️  Token will be verified on next network request');
            state = AuthStateData.authenticated(cached);
            return;
          }
        }
      } catch (e) {
        debugPrint('[Auth] ❌ Unexpected error: $e');
        final cached = await _getCachedUser();
        if (cached != null) {
          debugPrint('[Auth] ✅ Restored from cache: ${cached.email}');
          state = AuthStateData.authenticated(cached);
          return;
        }
      }
    } else {
      debugPrint('[Auth] ❌ No token found in secure storage');
    }

    debugPrint('[Auth] Unauthenticated - showing login screen');
    state = AuthStateData.unauthenticated();
  }

  Future<void> loginWithEmail(String email, String password) async {
    try {
      debugPrint('[Auth] loginWithEmail starting for: $email');
      state = state.copyWith(state: AuthState.authenticating);
      final result = await authService.loginWithEmail(email, password);
      debugPrint('[Auth] Login API call successful');
      if (result.token != null) {
        debugPrint('[Auth] Token received (${result.token!.length} chars), saving to storage...');
        await secureStorage.write(key: _tokenKey, value: result.token);
        debugPrint('[Auth] ✅ Token saved to secure storage');
      } else {
        debugPrint('[Auth] ❌ No token in login response!');
      }
      await _cacheUser(result.user);
      debugPrint('[Auth] ✅ User cached: ${result.user.email}');
      state = AuthStateData.authenticated(result.user);
    } catch (e) {
      debugPrint('[Auth] ❌ Login failed: $e');
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

  /// Sign in with the device's Google account (native account picker).
  /// Falls back to WebView if native sign-in fails (e.g., missing google-services.json).
  Future<bool> loginWithGoogle() async {
    try {
      debugPrint('[Auth] Google Sign-In starting...');
      state = state.copyWith(state: AuthState.authenticating);
      final service = GoogleSignInService();
      final googleResult = await service.signInWithGoogle();
      debugPrint('[Auth] Google account selected, exchanging for BeMusic token...');

      final result = await authService.loginWithGoogleToken(
        accessToken: googleResult.accessToken,
        idToken: googleResult.idToken,
      );
      debugPrint('[Auth] ✅ Google OAuth exchange successful');

      if (result.token != null) {
        debugPrint('[Auth] Token received (${result.token!.length} chars), saving to storage...');
        await secureStorage.write(key: _tokenKey, value: result.token);
        debugPrint('[Auth] ✅ Token saved to secure storage');
      } else {
        debugPrint('[Auth] ❌ No token in Google login response!');
      }
      await _cacheUser(result.user);
      debugPrint('[Auth] ✅ Google login successful: ${result.user.email}');
      state = AuthStateData.authenticated(result.user);
      return true; // native sign-in succeeded
    } catch (e) {
      debugPrint('[Auth] ❌ Native Google Sign-In failed: $e');
      state = AuthStateData.unauthenticated(); // reset so UI shows sign-in options
      return false; // caller should fall back to WebView
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

// Cache the Dio instance to ensure consistent token state across app lifecycle
Dio? _cachedDioInstance;

final authServiceProvider = Provider((ref) {
  try {
    return ref.watch(dioProvider).when(
      data: (dio) {
        _cachedDioInstance = dio;
        debugPrint('[AuthService] Using Dio from dioProvider');
        return AuthService(dio);
      },
      loading: () {
        debugPrint('[AuthService] dioProvider loading, using cached instance');
        if (_cachedDioInstance != null) {
          return AuthService(_cachedDioInstance!);
        }
        final fallback = Dio(BaseOptions(baseUrl: 'https://www.elsfm.com/api/v1'));
        _cachedDioInstance = fallback;
        return AuthService(fallback);
      },
      error: (err, st) {
        debugPrint('[AuthService] dioProvider error: $err');
        throw err;
      },
    );
  } catch (e) {
    debugPrint('[AuthService] Exception in authServiceProvider: $e');
    if (_cachedDioInstance != null) {
      return AuthService(_cachedDioInstance!);
    }
    final fallback = Dio(BaseOptions(baseUrl: 'https://www.elsfm.com/api/v1'));
    _cachedDioInstance = fallback;
    return AuthService(fallback);
  }
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthStateData>((ref) {
  final authService = ref.watch(authServiceProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthNotifier(authService: authService, secureStorage: secureStorage);
});
