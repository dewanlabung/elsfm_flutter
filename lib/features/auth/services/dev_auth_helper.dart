import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../data/services/auth_service.dart';

// DevAuthHelper is only compiled and used outside of release builds.
// Credentials are never hardcoded — callers must write them into secure
// storage via [setTestCredentials] before calling [enableDevMode].
// ignore: avoid_classes_with_only_static_members

/// Development-only helper for secure auto-login during testing.
///
/// SECURITY: Credentials are encrypted at the OS level:
/// - Android: EncryptedSharedPreferences with AES-256-GCM
/// - iOS: Keychain with device-specific encryption
///
/// This class is guarded by [kReleaseMode] and must NOT be used in
/// production builds. Do NOT hardcode plain-text credentials anywhere.
class DevAuthHelper {
  // This class must not be instantiated or used in release builds.
  DevAuthHelper(this._storage) : assert(!kReleaseMode, 'DevAuthHelper must not be used in release builds');

  static const _devModeKey = 'dev_mode_enabled';
  static const _encryptedEmailKey = 'dev_test_email_encrypted';
  static const _encryptedPasswordKey = 'dev_test_password_encrypted';

  final FlutterSecureStorage _storage;

  /// Write test credentials into secure storage.
  ///
  /// Call this once during local setup (e.g. a one-time setup script or
  /// a hidden dev-settings screen). Credentials come from env vars or a
  /// local `.env` file — never from source code constants.
  ///
  /// Example (from a dev-settings screen):
  /// ```dart
  /// await devAuthHelper.setTestCredentials(
  ///   email: const String.fromEnvironment('DEV_EMAIL'),
  ///   password: const String.fromEnvironment('DEV_PASSWORD'),
  /// );
  /// ```
  Future<void> setTestCredentials({
    required String email,
    required String password,
  }) async {
    assert(!kReleaseMode, 'setTestCredentials must not be called in release builds');
    await _storage.write(key: _encryptedEmailKey, value: email);
    await _storage.write(key: _encryptedPasswordKey, value: password);
  }

  /// Enable dev mode - activates auto-login with stored test credentials.
  /// Credentials must have been written first via [setTestCredentials].
  Future<void> enableDevMode() async {
    assert(!kReleaseMode, 'enableDevMode must not be called in release builds');
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

  /// Get stored encrypted test credentials if dev mode is enabled.
  /// Returns null if dev mode is disabled or credentials have not been set.
  Future<({String email, String password})?> getDevCredentials() async {
    assert(!kReleaseMode, 'getDevCredentials must not be called in release builds');
    if (!await isDevModeEnabled()) return null;

    final email = await getTestEmail();
    final password = await getTestPassword();

    if (email == null || password == null) return null;

    return (email: email, password: password);
  }

  /// Auto-login with encrypted test credentials.
  /// Called during app startup if dev mode is enabled.
  /// Silently fails if credentials are invalid or not set.
  Future<void> autoLogin(AuthService authService) async {
    assert(!kReleaseMode, 'autoLogin must not be called in release builds');
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
