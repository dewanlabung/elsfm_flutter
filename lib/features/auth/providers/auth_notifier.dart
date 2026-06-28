import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../data/providers/http_client_provider.dart';
import '../../../data/services/auth_service.dart';
import '../models/auth_state.dart';
import '../services/biometric_auth_service.dart';
import '../services/dev_auth_helper.dart';
import '../services/google_sign_in_service.dart';

const _tokenKey = 'auth_token';

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

  Future<void> _initAuth() async {
    try {
      state = state.copyWith(state: AuthState.authenticating);

      // 1. Try biometric login first if enabled
      final biometricToken = await biometricService.authenticateWithBiometric();
      if (biometricToken != null) {
        authService.setToken(biometricToken);
        final user = await authService.getCurrentUser();
        state = AuthStateData.authenticated(user);
        return;
      }

      // 2. Try saved token
      final savedToken = await secureStorage.read(key: _tokenKey);
      if (savedToken != null) {
        authService.setToken(savedToken);
        final user = await authService.getCurrentUser();
        state = AuthStateData.authenticated(user);
        return;
      }

      // 3. Try dev-mode auto-login if no saved token
      final devAuth = DevAuthHelper(secureStorage);
      await devAuth.autoLogin(authService);
      final user = await authService.getCurrentUser();
      state = AuthStateData.authenticated(user);
    } catch (e) {
      await secureStorage.delete(key: _tokenKey);
      authService.clearToken();
      state = AuthStateData.unauthenticated();
    }
  }

  Future<void> loginWithEmail(String email, String password) async {
    try {
      state = state.copyWith(state: AuthState.authenticating);
      final result = await authService.loginWithEmail(email, password);
      if (result.token != null) {
        await secureStorage.write(key: _tokenKey, value: result.token);
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

      if (googleResult.idToken == null || googleResult.email == null) {
        throw Exception('Google sign-in failed: Missing credentials');
      }

      final result = await authService.loginWithGoogle(
        googleResult.idToken!,
        googleResult.email!,
      );

      if (result.token != null) {
        await secureStorage.write(key: _tokenKey, value: result.token!);
      }

      state = AuthStateData.authenticated(result.user);
    } catch (e) {
      state = AuthStateData.error('Google sign-in failed: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      await authService.logout();
      await secureStorage.delete(key: _tokenKey);
      await biometricService.disableBiometric();
      state = AuthStateData.unauthenticated();
    } catch (e) {
      state = AuthStateData.error(e.toString());
    }
  }

  /// Enable biometric login with current authentication token
  Future<void> enableBiometricLogin() async {
    try {
      final token = await secureStorage.read(key: _tokenKey);
      if (token != null) {
        await biometricService.enableBiometric(token);
        if (kDebugMode) {
          debugPrint('✓ Biometric login enabled');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error enabling biometric: $e');
      }
    }
  }

  /// Disable biometric login
  Future<void> disableBiometricLogin() async {
    try {
      await biometricService.disableBiometric();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error disabling biometric: $e');
      }
    }
  }
}

final secureStorageProvider = Provider((ref) {
  return const FlutterSecureStorage();
});

final authServiceProvider = Provider((ref) {
  return ref.watch(dioProvider).when(
    data: (dio) => AuthService(dio),
    loading: () => throw Exception('Dio not ready'),
    error: (err, st) => throw err,
  );
});

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthStateData>((ref) {
  final authService = ref.watch(authServiceProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthNotifier(
    authService: authService,
    secureStorage: secureStorage,
  );
});
