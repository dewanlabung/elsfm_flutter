import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../data/services/auth_service.dart';

/// Development-only helper to skip login during testing
class DevAuthHelper {
  static const _devModeKey = 'dev_mode_enabled';
  static const _testEmailKey = 'dev_test_email';
  static const _testPasswordKey = 'dev_test_password';

  static const testEmail = 'live.elsfm@gmail.com';
  static const testPassword = '457862@aAa';

  final FlutterSecureStorage _storage;

  DevAuthHelper(this._storage);

  /// Enable dev mode - stores test credentials for quick login
  Future<void> enableDevMode() async {
    await _storage.write(key: _devModeKey, value: 'true');
    await _storage.write(key: _testEmailKey, value: testEmail);
    await _storage.write(key: _testPasswordKey, value: testPassword);
  }

  /// Disable dev mode
  Future<void> disableDevMode() async {
    await _storage.delete(key: _devModeKey);
    await _storage.delete(key: _testEmailKey);
    await _storage.delete(key: _testPasswordKey);
  }

  /// Check if dev mode is enabled
  Future<bool> isDevModeEnabled() async {
    final value = await _storage.read(key: _devModeKey);
    return value == 'true';
  }

  /// Get stored test credentials
  Future<({String email, String password})?> getDevCredentials() async {
    if (!await isDevModeEnabled()) return null;

    final email = await _storage.read(key: _testEmailKey);
    final password = await _storage.read(key: _testPasswordKey);

    if (email == null || password == null) return null;

    return (email: email, password: password);
  }

  /// Auto-login with stored dev credentials
  Future<void> autoLogin(AuthService authService) async {
    final creds = await getDevCredentials();
    if (creds == null) return;

    try {
      await authService.loginWithEmail(creds.email, creds.password);
    } catch (e) {
      // Dev mode login failed - that's ok, user can retry manually
      // Silent failure - user can retry manual login
    }
  }
}
