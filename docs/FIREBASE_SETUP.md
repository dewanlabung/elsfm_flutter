# Firebase Setup for Google Sign-In

## Prerequisites

- Google Cloud Project created
- Firebase project linked to Google Cloud Project
- Android and iOS apps registered in Firebase Console

## Android Setup

### 1. Download google-services.json

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project → Project Settings
3. Download `google-services.json` for Android app
4. Place in `android/app/google-services.json`

### 2. Update android/build.gradle

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

### 3. Update android/app/build.gradle

```gradle
plugins {
    id 'com.android.application'
    id 'kotlin-android'
    id 'com.google.gms.google-services'  // Add this line
}
```

### 4. Update AndroidManifest.xml

Add internet permission if not present:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

---

## iOS Setup

### 1. Download GoogleService-Info.plist

1. Go to Firebase Console → Project Settings
2. Download `GoogleService-Info.plist` for iOS app
3. Open `ios/Runner.xcworkspace` in Xcode
4. Drag GoogleService-Info.plist into Runner project
5. Ensure "Copy items if needed" is checked
6. Verify it's in both Runner target and Runner Tests target

### 2. Update ios/Podfile

Add pods dependencies:

```ruby
target 'Runner' do
  flutter_root = File.expand_path(File.join(packages_root, '.packages'), __dir__)
  load File.join(flutter_root, 'packages', 'flutter_tools', 'bin', 'podhelper')

  flutter_ios_podfile_setup

  pod 'Firebase/Core'
  pod 'Firebase/Auth'
  pod 'GoogleSignIn', '~> 6.0'
end
```

Then run: `cd ios && pod install --repo-update && cd ..`

---

## Main.dart Setup

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}
```

---

## Generate FirebaseOptions

Run this command to auto-generate firebase_options.dart:

```bash
flutterfire configure
```

This will:
- Detect your Firebase project
- Generate lib/firebase_options.dart
- Update pubspec.yaml if needed

---

## Update pubspec.yaml

Add dependencies:

```yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_auth: ^4.16.0
  google_sign_in: ^6.2.0
```

Then run:
```bash
flutter pub get
```

---

## Testing

### Android Emulator

Google Sign-In requires Google Play Services. Make sure your emulator has:
- Google APIs image (not standard Android image)
- Google Play Services installed

### Physical Device

Just works - no special setup needed.

### iOS Simulator

Google Sign-In may have issues on simulator. Test on physical device if possible.

---

## Troubleshooting

**"google-services.json not found"**
- Ensure file is in `android/app/google-services.json`
- Run `flutter clean && flutter pub get`

**"Firebase not initialized"**
- Ensure Firebase.initializeApp() is called in main()
- Add await and WidgetsFlutterBinding.ensureInitialized()

**"Google Sign-In fails on Android"**
- Verify SHA-1 fingerprint is added to Firebase Console
- Get fingerprint: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`

**iOS pod errors**
- Run `cd ios && pod deintegrate && pod install && cd ..`
- Clean: `flutter clean`

---

## OAuth Consent Screen

1. Go to Google Cloud Console → OAuth consent screen
2. Configure external or internal
3. Add scopes: `email`, `profile`, `openid`
4. Add test users if using external
