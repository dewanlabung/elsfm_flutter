# Phase 2: Complete Authentication System

## Overview

Build a production-ready authentication system with Google Sign-In, password saving, biometric auth, and Material 3 UI improvements.

## Implementation Order

### **Part 1: Google Sign-In + Firebase (1.5 hours)**

1. **Setup Firebase**
   - Add firebase_core, google_sign_in, firebase_auth to pubspec.yaml
   - Initialize Firebase in main.dart
   - Create google-services.json (Android) and GoogleService-Info.plist (iOS)

2. **Implement GoogleSignInService**
   - Wrapper around Google Sign-In + Firebase Auth
   - Methods: signInWithGoogle(), signOut()
   - Returns user profile (email, name, avatar)

3. **Update AuthService**
   - Add signInWithGoogle() method
   - Exchange Google token for backend session token
   - Store token in secure storage

4. **Update LoginScreen**
   - Replace existing Google button with proper Google Sign-In flow
   - Handle Firebase auth state
   - Show loading/error states

5. **Test Google Sign-In**
   - Create test account in Firebase Console
   - Verify sign-in works on Android device

---

### **Part 2: Password Credential Saving (45 minutes)**

1. **Update AuthService**
   - After successful login, save credentials option
   - Retrieve saved credentials for auto-fill

2. **Create CredentialManager widget**
   - Option to "Remember me" checkbox
   - Save email + password securely (or just email for password managers)
   - Auto-fill email on login screen

3. **Update LoginScreen**
   - Add "Remember me" checkbox
   - Auto-populate email field if credentials exist
   - Clear saved credentials on logout

4. **Test Password Saving**
   - Login with credentials
   - Check "Remember me"
   - Logout and reopen app
   - Verify email is auto-filled

---

### **Part 3: Material 3 Polish (1 hour)**

1. **Password Visibility Toggle**
   - Add eye icon button to password field
   - Toggle obscureText when tapped
   - Smooth animation on toggle

2. **Form Validation**
   - Real-time email validation
   - Visual feedback for invalid input
   - Error messages below fields

3. **Loading States**
   - Replace button with progress indicator
   - Disable all form inputs during auth
   - Show loading skeleton on first screen load

4. **Error Handling**
   - Beautiful error dialogs
   - Retry button for failed logins
   - Network error recovery suggestions

5. **Theme Improvements**
   - Consistent spacing and shadows
   - Smooth transitions
   - Accessible color contrast

---

### **Part 4: Biometric Authentication (1 hour) - OPTIONAL**

1. **Add biometric_storage package**

2. **Create BiometricAuthService**
   - Check device biometric capability
   - Save biometric token
   - Authenticate with biometric

3. **Add Biometric Option**
   - Button below email/password fields
   - Show when saved credentials exist
   - Fallback to password if biometric fails

4. **Test Biometric**
   - Enable biometric on Android device
   - Verify authentication flow works

---

### **Part 5: Playback Control Bar (2 hours) - OPTIONAL**

1. **Create PlaybackControlBar widget**
   - Display current track info
   - Play/pause/skip buttons
   - Progress bar with seek support
   - Collapse/expand animation

2. **Integrate with AudioService**
   - Listen to playback state
   - Update UI in real-time
   - Handle background audio

3. **Add to HomeScreen**
   - Show at bottom of screen
   - Persist during navigation
   - Tap to open full player

---

## File Structure

```
lib/features/auth/
├── services/
│   ├── google_sign_in_service.dart      (NEW)
│   ├── credential_manager.dart          (NEW)
│   ├── biometric_auth_service.dart      (NEW - optional)
│   └── auth_service.dart                (UPDATED)
├── widgets/
│   ├── password_field.dart              (NEW - with visibility toggle)
│   ├── email_field.dart                 (NEW - with validation)
│   ├── credential_saver.dart            (NEW)
│   └── dev_mode_toggle.dart             (EXISTING)
├── screens/
│   └── login_screen.dart                (UPDATED)
└── providers/
    ├── google_signin_provider.dart      (NEW)
    └── credential_provider.dart         (NEW)

lib/features/player/                     (NEW - optional)
├── widgets/
│   └── playback_control_bar.dart
└── providers/
    └── playback_provider.dart
```

---

## Dependencies to Add

```yaml
# Google Sign-In & Firebase
firebase_core: ^2.24.0
firebase_auth: ^4.16.0
google_sign_in: ^6.2.0

# Biometric (optional)
biometric_storage: ^5.0.0

# Additional utilities
form_builder_validators: ^9.0.0
```

---

## Key Features

- ✅ Email/password login with validation
- ✅ Google Sign-In with Firebase
- ✅ Password credential saving ("Remember me")
- ✅ Biometric authentication (fingerprint/face)
- ✅ Material 3 UI with smooth animations
- ✅ Automatic token refresh
- ✅ Secure credential storage
- ✅ Clean error handling
- ✅ Dev mode for testing

---

## Testing Checklist

- [ ] Email login works
- [ ] Google Sign-In works
- [ ] Credentials save and auto-fill
- [ ] Biometric unlock works
- [ ] Token refreshes automatically
- [ ] Logout clears all credentials
- [ ] Error messages are helpful
- [ ] UI is responsive (all screen sizes)
- [ ] Navigation flows smoothly
- [ ] Background audio continues after navigation

---

## Timeline

**Quick Path (3 hours):**
- Parts 1-3 only (Google Sign-In + Password Saving + Material 3)

**Complete Path (6 hours):**
- All 5 parts + comprehensive testing

**Recommended:** Start with Parts 1-3, then add biometric + playback bar in a follow-up.
