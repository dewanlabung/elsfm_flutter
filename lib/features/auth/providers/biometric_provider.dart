import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/biometric_auth_service.dart';

final biometricAuthServiceProvider = Provider<BiometricAuthService>((ref) {
  const storage = FlutterSecureStorage();
  return BiometricAuthService(storage);
});

/// Check if device supports biometric
final biometricSupportProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(biometricAuthServiceProvider);
  return await service.canUseBiometrics();
});

/// Check if biometric is currently enabled
final biometricEnabledProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(biometricAuthServiceProvider);
  return await service.isBiometricEnabled();
});
