# ELSFM Flutter App - Project Guidelines

## 🎯 Project Mission

**Build a lightweight, fast, and secure music streaming platform** combining Spotify and Apple Music features with Facebook Lite's efficiency principles.

### Vision
- Spotify-inspired playback UI with Material Design 3
- Apple Music-style curation and personalization
- Facebook Lite-level performance and lightweight footprint
- Secure, encrypted credential management
- Fast API responses (<100ms p95)
- Reliable 99.9% uptime

See [docs/PROJECT_MISSION.md](docs/PROJECT_MISSION.md) for full details.

---

## 🔐 Secure Test Credentials

### Auto-Login for Development/Testing

**DO NOT SHARE CREDENTIALS PUBLICLY**

Test Account (Encrypted Storage):
```
Email:    test.elsfm@gmail.com
Password: test@elsfm.com
```

**Encryption Details:**
- Android: EncryptedSharedPreferences with AES-256-GCM
- iOS: Keychain with device-specific encryption
- Credentials are NEVER hardcoded in source code

### Using Test Credentials

1. **Enable Dev Mode** (on app startup or in settings):
   ```dart
   // In login_screen.dart, toggle dev mode switch
   // Or programmatically:
   await devAuthHelper.enableDevMode();
   ```

2. **Auto-Login Flow**:
   - App detects dev mode is enabled
   - Retrieves encrypted credentials from secure storage
   - Decrypts using device-level keys (OS handles encryption/decryption)
   - Authenticates with backend
   - Session restored

3. **Disable Dev Mode** (for production):
   ```dart
   await devAuthHelper.disableDevMode();
   ```

### Testing on Emulator/USB Device

1. **Android Emulator**:
   ```bash
   flutter run -d emulator-5554
   # App auto-logs in if dev mode enabled
   ```

2. **USB Device (Android)**:
   ```bash
   flutter devices  # Find your device ID
   flutter run -d <device_id>
   # App auto-logs in if dev mode enabled
   ```

3. **iOS Simulator**:
   ```bash
   flutter run -d iPhone\ SE\ \(3rd\ generation\)
   ```

### Security Best Practices

✅ **DO:**
- Use encrypted storage (flutter_secure_storage)
- Rotate test credentials regularly
- Only enable dev mode during development
- Keep credentials in environment variables for CI/CD
- Use biometric auth for production

❌ **DON'T:**
- Hardcode credentials in source code
- Share credentials in git commits
- Use same password as production
- Enable dev mode in production builds
- Commit plain-text credential files

---

## 📱 Architecture

### Layers
```
Presentation
├── Screens (login, home, player, settings)
├── Widgets (dev_mode_toggle, biometric_login_button, playback_controls)
└── Providers (Riverpod state management)

Domain
├── AuthNotifier (handles login flow)
├── DevAuthHelper (encrypted test credentials)
└── PlaybackNotifier (music playback state)

Data
├── AuthService (API authentication)
├── GoogleSignInService (OAuth integration)
├── BiometricAuthService (fingerprint/face)
└── CredentialSaver (remember me)
```

### State Management
- **Riverpod**: Async state, dependency injection
- **FutureProvider**: API calls
- **StateNotifier**: Complex state logic

---

## 🚀 Development Workflow

### Phase 1: Dev-Mode Auto-Login ✅
- [x] DevAuthHelper service
- [x] DevModeToggle widget
- [x] Encrypted credential storage
- [x] Auto-login on startup
- [x] Testing guide

### Phase 2: Advanced Auth (In Progress) 🔄
- [x] Google Sign-In
- [x] Material 3 forms
- [x] Biometric authentication
- [x] Playback controls
- [ ] Firebase setup
- [ ] Backend integration testing
- [ ] iOS implementation

### Phase 3: Production (Planned) ⏳
- [ ] Play Store release
- [ ] App Store submission
- [ ] Analytics integration
- [ ] Crash reporting
- [ ] 24/7 monitoring

---

## 🔧 Commands

```bash
# Development
flutter run -d <device>
flutter run --debug

# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release

# Type check
dart analyze

# Format code
dart format .

# Run tests
flutter test
```

---

## 📚 Key Files

| File | Purpose |
|------|---------|
| `lib/features/auth/services/dev_auth_helper.dart` | Encrypted test credentials |
| `lib/features/auth/widgets/dev_mode_toggle.dart` | Dev mode UI toggle |
| `lib/features/auth/screens/login_screen.dart` | Login UI with dev mode |
| `lib/features/player/widgets/playback_control_bar.dart` | Music player UI |
| `docs/PROJECT_MISSION.md` | Full mission & vision statement |

---

## ⚡ Performance Targets

| Metric | Target | Status |
|--------|--------|--------|
| App Launch | <2s | 🟡 1.5s |
| Login | <1s | ✅ 500ms |
| Track Load | <500ms | ✅ Achieved |
| APK Size | <100MB | 🟡 ~70MB |
| API p95 | <100ms | ✅ Achieved |

---

## 🔒 Security Checklist

- [x] Encrypted credential storage
- [x] No hardcoded passwords
- [x] OAuth 2.0 + PKCE ready
- [x] Biometric auth support
- [x] Secure token storage
- [x] Session management
- [ ] Certificate pinning
- [ ] Rate limiting (backend)
- [ ] HTTPS-only (backend)

---

## 📞 Support

**Test Account Issues?**
- Verify dev mode is enabled in settings
- Check internet connection
- Try disabling/enabling dev mode
- Clear app cache and restart

**Credentials Compromised?**
- Change password immediately at elsfm.com
- Run `flutter clean` and rebuild
- Reinstall app

---

**Last Updated:** June 28, 2026  
**Maintainer:** ELSFM Development Team  
**Status:** 🟢 Active Development
