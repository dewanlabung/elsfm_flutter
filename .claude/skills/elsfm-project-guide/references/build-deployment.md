# Build & Deployment

Release builds for Play Store and App Store.

## Version

Update in `pubspec.yaml`:

```yaml
version: 1.0.0+1  # version+buildNumber
```

## Android

### APK (Debug)
```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-app.apk
```

### APK/AAB (Release)
```bash
# Create keystore (once)
keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Build AAB (preferred for Play Store)
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab

# Or APK
flutter build apk --release
```

### Signing Config

Create `android/key.properties`:

```properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=key.jks
```

Reference in `android/app/build.gradle`:

```gradle
signingConfigs {
  release {
    keyAlias keystoreProperties['keyAlias']
    keyPassword keystoreProperties['keyPassword']
    storeFile file(keystoreProperties['storeFile'])
    storePassword keystoreProperties['storePassword']
  }
}
```

## iOS

### Build Archive
```bash
flutter build ios --release
# Open in Xcode and archive
open ios/Runner.xcworkspace

# Or directly
flutter build ios --release --export-method app-store
```

### Provisioning

1. Apple Developer account
2. Create App ID
3. Create Provisioning Profile
4. Download and install in Xcode

### TestFlight

1. Archive in Xcode
2. Organizer → Upload
3. Select provisioning profile
4. Submit for review
5. Invite testers

## Play Store Release

1. **Prepare**
   - Icon (512x512)
   - Screenshots (2-8 per device)
   - Description, keywords
   - Privacy policy URL
   - Content rating

2. **Upload**
   - Build → AAB
   - Upload to Play Console
   - Review content rating

3. **Review**
   - Google reviews (~24hrs)
   - May request changes

4. **Release**
   - Rollout (5% → 50% → 100%)
   - Monitor crash rate

## App Store Release

1. **Prepare**
   - Icon (1024x1024)
   - Screenshots (6-8 per device)
   - Preview video (optional)
   - Description, keywords

2. **Upload**
   - Archive in Xcode
   - Organizer → Upload to App Store

3. **Review**
   - Apple reviews (~48hrs)
   - Usually stricter than Play Store

4. **Release**
   - Phased rollout (7 days)
   - Monitor crash rate

## Checklist

- [ ] Version bumped
- [ ] Build passes analysis (`dart analyze`)
- [ ] All tests pass (`flutter test`)
- [ ] Signing keys configured
- [ ] Store screenshots prepared
- [ ] Privacy policy updated
- [ ] Release notes written
- [ ] Analytics configured
- [ ] Crashlytics enabled
- [ ] Device testing complete
