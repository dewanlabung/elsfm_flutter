import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Biometric authentication service (fingerprint, face recognition)
class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _storage;

  static const _biometricEnabledKey = 'biometric_enabled';
  static const _biometricTokenKey = 'biometric_token';

  BiometricAuthService(this._storage);

  /// Check if device supports biometric authentication
  Future<bool> canUseBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics &&
          await _localAuth.deviceSupportsFaceID() ||
          await _localAuth.deviceSupportsFingerprint();
    } catch (e) {
      return false;
    }
  }

  /// Get list of available biometrics
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Enable biometric authentication with a token
  Future<void> enableBiometric(String authToken) async {
    try {
      await _storage.write(key: _biometricTokenKey, value: authToken);
      await _storage.write(key: _biometricEnabledKey, value: 'true');
    } catch (e) {
      rethrow;
    }
  }

  /// Authenticate using biometric
  Future<String?> authenticateWithBiometric() async {
    try {
      final isEnabled = await _isBiometricEnabled();
      if (!isEnabled) return null;

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Unlock ELSFM with your biometric',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        return await _storage.read(key: _biometricTokenKey);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if biometric is enabled
  Future<bool> _isBiometricEnabled() async {
    final value = await _storage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  /// Disable biometric authentication
  Future<void> disableBiometric() async {
    await _storage.delete(key: _biometricEnabledKey);
    await _storage.delete(key: _biometricTokenKey);
  }

  /// Check if biometric is currently enabled
  Future<bool> isBiometricEnabled() async {
    return await _isBiometricEnabled();
  }
}
