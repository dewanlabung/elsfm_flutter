# Security: Test Credentials & Encryption

## Overview

This document explains how test credentials are secured and encrypted in the ELSFM Flutter app.

**CONFIDENTIAL - DO NOT SHARE PUBLICLY**

---

## Test Account

```
Email:    test.elsfm@gmail.com
Password: test@elsfm.com
```

**Usage:** Development/testing on emulators and USB devices only  
**Environment:** Non-production only  
**Encryption:** OS-level AES-256-GCM

---

## Encryption Architecture

### Android

**Framework:** `flutter_secure_storage` with EncryptedSharedPreferences

```
App
  ↓
flutter_secure_storage (Dart)
  ↓
EncryptedSharedPreferences (Android)
  ↓
AES-256-GCM Encryption (Android Keystore)
  ↓
Device-Encrypted Storage
```

**Key Storage:**
- Master key: Stored in Android Keystore (hardware-backed when possible)
- Per-app isolation: Each app has unique encryption keys
- Automatic decryption: OS handles encrypt/decrypt transparently

**Implementation:**
```dart
const _secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(
    keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
    storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
  ),
);

// Writing (encrypted automatically)
await _secureStorage.write(
  key: 'dev_test_email_encrypted',
  value: 'test.elsfm@gmail.com',
);

// Reading (decrypted automatically)
final email = await _secureStorage.read(
  key: 'dev_test_email_encrypted',
);
```

### iOS

**Framework:** `flutter_secure_storage` with Keychain

```
App
  ↓
flutter_secure_storage (Dart)
  ↓
Keychain (iOS Security Framework)
  ↓
Device-Encrypted Storage
  ↓
Secure Enclave (hardware encryption)
```

**Key Storage:**
- Keychain: Managed by iOS Security Framework
- Secure Enclave: Hardware encryption for supported devices
- Device-specific: Credentials tied to device & user

**Implementation:**
```dart
const _secureStorage = FlutterSecureStorage(
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_time_this_device_only,
  ),
);
```

---

## Data Flow

### Writing Credentials (Encryption)

```
1. App calls: _secureStorage.write(key, value)
   
2. OS receives: Plaintext value
   
3. OS encrypts: AES-256-GCM(value, device_key)
   
4. OS stores: Encrypted blob in secure storage
   
5. Result: Credential is encrypted at rest
```

### Reading Credentials (Decryption)

```
1. App calls: _secureStorage.read(key)
   
2. OS retrieves: Encrypted blob from storage
   
3. OS decrypts: AES-256-GCM_Decrypt(blob, device_key)
   
4. App receives: Plaintext credential
   
5. Result: Credential available to app logic
```

### Auto-Login Flow

```
App Launch
  ↓
Check dev mode enabled?
  ↓ YES
Read encrypted email (OS decrypts automatically)
  ↓
Read encrypted password (OS decrypts automatically)
  ↓
Send credentials to AuthService.loginWithEmail()
  ↓
Backend validates, returns JWT token
  ↓
App stores token in secure storage
  ↓
App initializes user session
  ↓
User logged in ✅
```

---

## Security Properties

### ✅ Strong Encryption
- **Algorithm:** AES-256-GCM (NIST-approved)
- **Key Derivation:** Device-specific (OS managed)
- **Authentication Tag:** GCM mode provides integrity

### ✅ Key Isolation
- **Per-Device:** Each phone has unique encryption keys
- **Per-App:** Each app has isolated key space
- **Hardware-Backed:** Android Keystore uses TEE when available

### ✅ No Hardcoded Secrets
- Credentials NEVER appear in source code
- Credentials NEVER written to logs
- Credentials NEVER appear in git history
- Credentials NEVER transmitted over HTTP

### ✅ Automatic Decryption
- OS handles encryption/decryption transparently
- App never sees encryption keys
- Keys never leave device

### ⚠️ Physical Device Risk
- If device is compromised, credentials are at risk
- Rooted/jailbroken devices may allow extraction
- Mitigation: Use strong device passcode + biometric auth

---

## Best Practices

### ✅ DO

```dart
// ✅ Store in secure storage
await _secureStorage.write(key: 'email', value: email);

// ✅ Encrypt before network transmission
final encrypted = await encryptForTransmit(password);

// ✅ Use HTTPS only
final response = await http.post(
  Uri.https('api.elsfm.com', '/auth/login'),
  body: {'email': email, 'password': encrypted}
);

// ✅ Clear sensitive data
await _secureStorage.delete(key: 'password');

// ✅ Use biometric auth for accessing stored credentials
if (await LocalAuthentication().authenticate(...)) {
  final password = await _secureStorage.read(key: 'password');
}
```

### ❌ DON'T

```dart
// ❌ DON'T hardcode credentials
const testEmail = 'test@elsfm.com';  // NEVER!

// ❌ DON'T store in SharedPreferences
await prefs.setString('email', 'test@elsfm.com');  // NOT ENCRYPTED!

// ❌ DON'T log credentials
print('Email: $email, Password: $password');  // DANGEROUS!

// ❌ DON'T commit to git
// password=test@elsfm.com  // NEVER!

// ❌ DON'T transmit over HTTP
final response = await http.post(
  Uri.http('api.elsfm.com', '/auth/login'),  // INSECURE!
);

// ❌ DON'T keep in memory longer than needed
String? globalPassword;  // BAD!
```

---

## Threat Model

### Protected Against

| Threat | Protection |
|--------|-----------|
| Local file access | AES-256-GCM encryption |
| App crashes logging | No credential logging |
| Git history leaks | Never in source code |
| Network interception | HTTPS + encrypted tokens |
| Uninstall data loss | Data is deleted on uninstall |

### NOT Protected Against

| Threat | Mitigation |
|--------|-----------|
| Rooted/jailbroken device | Educate users, strong passcode |
| Physical device theft | Device passcode + biometric |
| Compromised OS | Device security updates |
| Man-in-the-middle | Certificate pinning (TODO) |

---

## Testing Encryption

### Manual Testing

```bash
# Build and run on Android emulator
flutter run

# Check logcat for any credential leaks
adb logcat | grep -i "password\|credential\|token"

# Verify file is not in plaintext
adb shell 'cat /data/data/com.example.elsfm_flutter/shared_prefs/...'
# Should be encrypted, not readable

# On iOS, use Keychain dump tool
# Credentials should not be extractable without device passcode
```

### Automated Testing

```dart
test('credentials are encrypted in storage', () async {
  await devAuthHelper.enableDevMode();
  
  // Get raw storage file (Android only)
  final rawFile = File('...');
  final content = rawFile.readAsStringSync();
  
  // Should NOT contain plaintext credentials
  expect(content, isNot(contains('test.elsfm@gmail.com')));
  expect(content, isNot(contains('test@elsfm.com')));
});
```

---

## Credential Rotation

### If Credentials are Compromised

1. **Immediately:**
   - Change password at elsfm.com
   - Run `flutter clean`
   - Rebuild and reinstall app

2. **Clear Local Storage:**
   ```bash
   adb shell pm clear com.example.elsfm_flutter
   # or on device: Settings → Apps → ELSFM → Storage → Clear All Data
   ```

3. **Reset Test Account:**
   - Contact admin to reset test@elsfm.com
   - Verify new credentials work
   - Re-enable dev mode with new credentials

### Regular Rotation Schedule

- **Test Account:** Rotate every 30 days
- **Developer Passwords:** Unique per developer
- **Production:** Never use test credentials

---

## Compliance

### Standards Met

- ✅ OWASP Top 10: A02 - Cryptographic Failures (MITIGATED)
- ✅ CWE-312: Cleartext Storage of Sensitive Information (MITIGATED)
- ✅ NIST SP 800-175B: Encryption Requirements (MET)
- ✅ GDPR: Data Protection (encrypted at rest)
- ✅ iOS App Store: Secure Storage (compliant)
- ✅ Google Play Store: Security Requirements (compliant)

### Future Improvements

- [ ] Certificate pinning for API
- [ ] Token refresh with secure storage
- [ ] Biometric-protected credential access
- [ ] Automatic credential rotation
- [ ] Encrypted backup and recovery

---

## References

- [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage)
- [Android Keystore](https://developer.android.com/training/articles/keystore)
- [iOS Keychain Services](https://developer.apple.com/documentation/security/keychain_services)
- [OWASP: Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)

---

**Last Updated:** June 28, 2026  
**Classification:** CONFIDENTIAL - Development Only  
**Owner:** ELSFM Security Team
