import 'package:dio/dio.dart' show DioException, Dio, BaseOptions;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../data/providers/http_client_provider.dart';
import '../../../data/services/auth_service.dart';
import '../models/auth_state.dart';
import '../services/biometric_auth_service.dart';
import '../services/google_sign_in_service.dart';

const _tokenKey = 'auth_token';

class AuthNotifier extends Notifier<AuthStateData> {
  late final AuthService _authService;
  late final FlutterSecureStorage _secureStorage;
  late final BiometricAuthService _biometricService;

  @override
  AuthStateData build() {
    _authService = ref.watch(authServiceProvider);
    _secureStorage = ref.watch(secureStorageProvider);
    _biometricService = BiometricAuthService(_secureStorage);
    // Kick off async init without blocking the synchronous build.
    Future.microtask(_initAuth);
    return AuthStateData.unauthenticated();
  }

  Future<void> _initAuth() async {
    state = state.copyWith(state: AuthState.authenticating);

    // 1. Try biometric login first if enabled.
    try {
      final biometricToken = await _biometricService.authenticateWithBiometric();
      if (biometricToken != null) {
        _authService.setToken(biometricToken);
        final user = await _authService.getCurrentUser();
        state = AuthStateData.authenticated(user);
        return;
      }
    } catch (e) {
      // Biometric failed — fall through to saved token.
      if (kDebugMode) debugPrint('Biometric init error: $e');
    }

    // 2. Try saved token (do not delete it on network errors).
    final savedToken = await _secureStorage.read(key: _tokenKey);
    if (savedToken != null) {
      try {
        _authService.setToken(savedToken);
        final user = await _authService.getCurrentUser();
        state = AuthStateData.authenticated(user);
        return;
      } on DioException catch (e) {
        // Only clear token on 401 Unauthorized — not network errors.
        if (e.response?.statusCode == 401) {
          await _secureStorage.delete(key: _tokenKey);
          _authService.clearToken();
        } else {
          if (kDebugMode) debugPrint('Network error during auth init: $e');
        }
        state = AuthStateData.unauthenticated();
        return;
      } catch (e) {
        if (kDebugMode) debugPrint('Auth init error: $e');
        state = AuthStateData.unauthenticated();
        return;
      }
    }

    // 3. No saved token — show login screen.
    state = AuthStateData.unauthenticated();
  }

  Future<void> loginWithEmail(String email, String password) async {
    try {
      state = state.copyWith(state: AuthState.authenticating);
      final result = await _authService.loginWithEmail(email, password);
      if (result.token != null) {
        await _secureStorage.write(key: _tokenKey, value: result.token);
      }
      state = AuthStateData.authenticated(result.user);
    } catch (e) {
      state = AuthStateData.error(e.toString());
    }
  }

  Future<void> loginWithGoogle(BuildContext context) async {
    try {
      state = state.copyWith(state: AuthState.authenticating);

      final googleService = GoogleSignInService();
      final googleResult = await googleService.signInWithGoogle();

      if (googleResult.accessToken == null) {
        throw Exception('Google sign-in failed: Missing access token');
      }

      final result = await _authService.loginWithGoogle(
        googleResult.accessToken!,
      );

      if (result.token != null) {
        await _secureStorage.write(key: _tokenKey, value: result.token!);
      }

      state = AuthStateData.authenticated(result.user);
    } catch (e) {
      state = AuthStateData.error('Google sign-in failed: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
      await _secureStorage.delete(key: _tokenKey);
      await _biometricService.disableBiometric();
      state = AuthStateData.unauthenticated();
    } catch (e) {
      state = AuthStateData.error(e.toString());
    }
  }

  /// Enable biometric login with the current authentication token.
  Future<void> enableBiometricLogin() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      if (token != null) {
        await _biometricService.enableBiometric(token);
        if (kDebugMode) debugPrint('Biometric login enabled');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error enabling biometric: $e');
    }
  }

  /// Disable biometric login.
  Future<void> disableBiometricLogin() async {
    try {
      await _biometricService.disableBiometric();
    } catch (e) {
      if (kDebugMode) debugPrint('Error disabling biometric: $e');
    }
  }
}

final secureStorageProvider = Provider((ref) {
  return const FlutterSecureStorage();
});

final authServiceProvider = Provider<AuthService>((ref) {
  // Use the async dioProvider; fall back to a plain Dio while it initialises.
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
