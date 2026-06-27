import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../data/providers/http_client_provider.dart';
import '../../../data/services/auth_service.dart';
import '../models/auth_state.dart';

class AuthNotifier extends StateNotifier<AuthStateData> {
  final AuthService authService;
  final FlutterSecureStorage secureStorage;

  AuthNotifier({
    required this.authService,
    required this.secureStorage,
  }) : super(AuthStateData.unauthenticated()) {
    _initAuth();
  }

  Future<void> _initAuth() async {
    try {
      state = state.copyWith(state: AuthState.authenticating);
      final user = await authService.getCurrentUser();
      state = AuthStateData.authenticated(user);
    } catch (e) {
      state = AuthStateData.unauthenticated();
    }
  }

  Future<void> loginWithEmail(String email, String password) async {
    try {
      state = state.copyWith(state: AuthState.authenticating);
      final user = await authService.loginWithEmail(email, password);
      state = AuthStateData.authenticated(user);
    } catch (e) {
      state = AuthStateData.error(e.toString());
    }
  }

  Future<void> loginWithGoogle(BuildContext context) async {
    try {
      state = state.copyWith(state: AuthState.authenticating);
      final user = await authService.getCurrentUser();
      state = AuthStateData.authenticated(user);
    } catch (e) {
      state = AuthStateData.error(e.toString());
    }
  }

  Future<void> logout() async {
    try {
      await authService.logout();
      state = AuthStateData.unauthenticated();
    } catch (e) {
      state = AuthStateData.error(e.toString());
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

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthStateData>((ref) {
  final authService = ref.watch(authServiceProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthNotifier(
    authService: authService,
    secureStorage: secureStorage,
  );
});
