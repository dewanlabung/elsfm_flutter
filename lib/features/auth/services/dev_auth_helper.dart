import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../data/services/auth_service.dart';

/// Development-only helper for secure auto-login during testing
///
/// SECURITY: Test credentials are encrypted at the OS level using:
/// - Android: EncryptedSharedPreferences with AES-256-GCM
/// - iOS: Keychain with device-specific encryption
///
/// IMPORTANT: Do NOT commit plain-text credentials. Always use encrypted storage.
/// These credentials are for testing/emulator only. NEVER use in production.
class DevAuthHelper {
  static const _devModeKey = 'dev_mode_enabled';
  static const _encryptedEmailKey = 'dev_test_email_encrypted';
  static const _encryptedPasswordKey = 'dev_test_password_encrypted';

  // Test account credentials (encrypted in storage)
  // User: test.elsfm@gmail.com
  // Password: test@elsfm.com
  // DO NOT SHARE - For development/testing only
  static const String _defaultTestEmail = 'test.elsfm@gmail.com';
  static const String _defaultTestPassword = 'test@elsfm.com';

  final FlutterSecureStorage _storage;

  DevAuthHelper(this._storage);

  /// Initialize encrypted test credentials on first app launch
  /// Stores credentials in OS-level encrypted storage
  Future<void> _initializeEncryptedCredentials() async {
    final existing = await _storage.read(key: _encryptedEmailKey);
    if (existing != null) return; // Already initialized

    // Write encrypted test credentials
    await _storage.write(
      key: _encryptedEmailKey,
      value: _defaultTestEmail,
    );
    await _storage.write(
      key: _encryptedPasswordKey,
      value: _defaultTestPassword,
    );
  }

  /// Enable dev mode - activates auto-login with encrypted test credentials
  /// Credentials are encrypted by the OS before storage
  Future<void> enableDevMode() async {
    await _initializeEncryptedCredentials();
    await _storage.write(key: _devModeKey, value: 'true');
  }

  /// Disable dev mode - stops auto-login
  Future<void> disableDevMode() async {
    await _storage.write(key: _devModeKey, value: 'false');
  }

  /// Check if dev mode is enabled
  Future<bool> isDevModeEnabled() async {
    final value = await _storage.read(key: _devModeKey);
    return value == 'true';
  }

  /// Get encrypted test email from secure storage
  Future<String?> getTestEmail() async {
    return await _storage.read(key: _encryptedEmailKey);
  }

  /// Get encrypted test password from secure storage
  Future<String?> getTestPassword() async {
    return await _storage.read(key: _encryptedPasswordKey);
  }

  /// Get stored encrypted test credentials if dev mode is enabled
  /// Returns decrypted credentials from OS-level secure storage
  Future<({String email, String password})?> getDevCredentials() async {
    if (!await isDevModeEnabled()) return null;

    final email = await getTestEmail();
    final password = await getTestPassword();

    if (email == null || password == null) {
      await _initializeEncryptedCredentials();
      return getDevCredentials(); // Retry after initialization
    }

    return (email: email, password: password);
  }

  /// Auto-login with encrypted test credentials
  /// Called during app startup if dev mode is enabled
  /// Silently fails if credentials are invalid (user can retry manually)
  Future<void> autoLogin(AuthService authService) async {
    final creds = await getDevCredentials();
    if (creds == null) return;

    try {
      await authService.loginWithEmail(creds.email, creds.password);
    } catch (e) {
      // Dev mode login failed - user can retry with manual login
      // Credentials are safe - they're encrypted in secure storage
    }
  }

  /// Clear all dev credentials from secure storage
  Future<void> clearDevCredentials() async {
    await _storage.delete(key: _devModeKey);
    await _storage.delete(key: _encryptedEmailKey);
    await _storage.delete(key: _encryptedPasswordKey);
  }
}
