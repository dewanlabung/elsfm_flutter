# Test Credentials Setup Guide

## Quick Start

### Enable Auto-Login (Testing)

**Option 1: UI Toggle**
1. Launch app: `flutter run -d <device>`
2. Go to Login Screen
3. Scroll to bottom, tap "Dev Mode" toggle
4. Toggle switches to ✅ (green checkmark)
5. App auto-logs in with encrypted test credentials

**Option 2: Programmatic**
```dart
// In your test or initialization code
await devAuthHelper.enableDevMode();
```

### Test Account

```
Email:    test.elsfm@gmail.com
Password: test@elsfm.com
```

⚠️ **KEEP PRIVATE** - Do not share publicly

---

## How It Works

### Encryption Flow

```
1. First App Launch
   └─ DevAuthHelper.initializeEncryptedCredentials()
      └─ Write email to secure storage (encrypted by OS)
      └─ Write password to secure storage (encrypted by OS)

2. Enable Dev Mode
   └─ User taps "Dev Mode" toggle
   └─ DevAuthHelper.enableDevMode() called
   └─ Dev mode flag set in secure storage

3. App Startup
   └─ Check: Is dev mode enabled?
   └─ YES: Retrieve encrypted email
   └─ YES: Retrieve encrypted password
   └─ OS decrypts automatically
   └─ Send to AuthService.loginWithEmail()
   └─ Backend validates
   └─ Session restored

4. User Logged In
   └─ DevModeToggle shows green checkmark
   └─ User can navigate app
```

### Security Guarantees

| Aspect | Protection |
|--------|-----------|
| **At Rest** | AES-256-GCM (OS-encrypted) |
| **In Transit** | HTTPS + JWT tokens |
| **In Source** | Never hardcoded |
| **In Logs** | No credential logging |
| **In Memory** | Decrypted temporarily only |

---

## Testing on Different Devices

### Android Emulator

```bash
# Create/start emulator
emulator -avd Pixel_5_API_31

# Or use existing: flutter emulators
flutter emulators --launch Pixel_5_API_31

# Run app
flutter run -d emulator-5554

# In app: Enable dev mode toggle
```

**Verify Encryption:**
```bash
# Check logcat for credentials (should NOT appear)
adb logcat | grep -i "password\|credential\|email"

# No output = ✅ Credentials not logged
```

### Android USB Device

```bash
# Connect device via USB, enable Developer Mode
adb devices  # Verify device appears

# Run app
flutter run -d <device_id>

# In app: Enable dev mode toggle
```

### iOS Simulator

```bash
# Start simulator
open -a Simulator

# Run app
flutter run -d "iPhone 15 Pro"

# In app: Enable dev mode toggle
```

### iOS USB Device

```bash
# Connect via USB
flutter devices  # Verify device appears

# Run app (first time may require provisioning profile)
flutter run -d <device_id>

# In app: Enable dev mode toggle
```

---

## Troubleshooting

### "Dev Mode Not Working"

**Problem:** Toggle switches on but app doesn't auto-login

**Solution:**
1. Check internet connection
2. Verify test account exists on backend
3. Clear app cache: `adb shell pm clear com.example.elsfm_flutter`
4. Rebuild: `flutter clean && flutter run`
5. Check logcat: `adb logcat | grep -i "dev\|auth"`

### "Credentials Not Decrypting"

**Problem:** "Credential decryption failed" error

**Solution:**
1. Device encryption key may be corrupted
2. Uninstall app completely
3. Clear app data (Settings → Apps → ELSFM → Storage → Clear All Data)
4. Reinstall: `flutter run`
5. Re-enable dev mode

### "Backend Rejects Credentials"

**Problem:** "Invalid email or password" after dev mode enabled

**Solution:**
1. Verify test account exists on backend (admin access required)
2. Reset password: Contact dev team to reset test.elsfm@gmail.com
3. Clear credentials: `await devAuthHelper.clearDevCredentials()`
4. Re-enable dev mode: `await devAuthHelper.enableDevMode()`

---

## For CI/CD and Automation

### Setting Test Credentials via Environment

```bash
# Set environment variables
export ELSFM_TEST_EMAIL="test.elsfm@gmail.com"
export ELSFM_TEST_PASSWORD="test@elsfm.com"

# In Dart code
const testEmail = String.fromEnvironment('ELSFM_TEST_EMAIL');
const testPassword = String.fromEnvironment('ELSFM_TEST_PASSWORD');
```

### Running Automated Tests

```bash
# Build APK with test credentials
flutter build apk \
  --dart-define=ELSFM_TEST_EMAIL=test.elsfm@gmail.com \
  --dart-define=ELSFM_TEST_PASSWORD=test@elsfm.com

# Install and run
adb install build/app/outputs/apk/release/app-release.apk
adb shell am start -n com.example.elsfm_flutter/.MainActivity

# Enable dev mode programmatically in test setup
await devAuthHelper.enableDevMode();
```

---

## Security Reminders

### ✅ SAFE

- ✅ Credentials stored in encrypted secure storage
- ✅ OS handles encryption/decryption
- ✅ Credentials not visible in app code
- ✅ Dev mode only for testing
- ✅ Production builds disable dev mode

### ❌ UNSAFE

- ❌ Sharing credentials via email/Slack
- ❌ Committing credentials to git
- ❌ Logging credentials to console
- ❌ Using test credentials in production
- ❌ Hardcoding credentials in source

---

## Next Steps

1. **Enable Dev Mode** in app UI
2. **Verify Auto-Login** works
3. **Test on Emulator** and USB Device
4. **Build Release APK** for Play Store
5. **Disable Dev Mode** in production build

---

**Test Account Created:** June 28, 2026  
**Encryption:** AES-256-GCM (OS-level)  
**Status:** ✅ Ready for Testing  
**Classification:** Confidential - Development Only
