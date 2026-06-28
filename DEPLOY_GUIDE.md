# ELSFM Flutter - Remote Build & Deploy Guide

Since your Mac's Flutter SDK is broken, we'll use GitHub Actions to build remotely and deploy the APK to USB.

## Step 1: Push to GitHub

```bash
# Navigate to project
cd ~/Documents/GitHub/elsfm_flutter

# Add your GitHub repo as remote (replace with your username)
git remote add origin https://github.com/YOUR_USERNAME/elsfm_flutter.git

# Push to main branch
git branch -M main
git push -u origin main
```

## Step 2: Trigger Remote Build

Once pushed, GitHub Actions will automatically:
1. ✅ Build Android APK on Ubuntu runners
2. ✅ Run tests
3. ✅ Create a GitHub Release with artifacts

**Or manually trigger:**
1. Go to: `https://github.com/YOUR_USERNAME/elsfm_flutter/actions`
2. Click "Build ELSFM Flutter App"
3. Click "Run workflow"

## Step 3: Download APK

Once build completes (~10-15 minutes):

1. Go to the Actions run in GitHub
2. Scroll to bottom → "Artifacts"
3. Download `elsfm-release-apk` (the APK file)
4. Or use GitHub Release (auto-created): `Releases` tab

## Step 4: Copy APK to USB

```bash
# Find USB drive
diskutil list

# Identify your USB (usually something like /dev/disk2)
# Then mount it (usually auto-mounts)

# Copy APK to USB
cp ~/Downloads/app-release.apk /Volumes/USB_NAME/

# Eject safely
diskutil eject /dev/disk2
```

## Step 5: Install on Android Device

**From USB:**
```bash
# Connect Android device via USB
# Enable Developer Mode & USB debugging

adb install /Volumes/USB_NAME/app-release.apk
```

**Direct from computer:**
```bash
adb install ~/Downloads/app-release.apk
```

## Artifacts Available

- **app-release.apk** — Android phone/tablet app (~50-60MB)
- **app-release.aab** — Android App Bundle for Google Play Store

## iOS (When Ready)

For iOS, you'll need:
1. Apple Developer Account
2. Signing Certificate (p12 file)
3. Provisioning Profile
4. Team ID

Then uncomment the iOS signing steps in `.github/workflows/build.yml` and add as GitHub Secrets:
- `APPLE_CERTIFICATE` (base64 encoded)
- `APPLE_CERTIFICATE_PASSWORD`
- `APPLE_TEAM_ID`
- `PROVISIONING_PROFILE` (base64 encoded)

See [iOS Code Signing Guide](https://docs.flutter.dev/deployment/ios#setup-xcode-project)

## Build Status

Check anytime at: `https://github.com/YOUR_USERNAME/elsfm_flutter/actions`

## Troubleshooting

**Build fails?**
- Check the action logs for error details
- Common issues: missing assets, test failures (usually non-blocking)

**APK not downloading?**
- Make sure the build completed successfully (green checkmark)
- Check you're logged into GitHub account with repo access

**Can't find USB?**
```bash
# List all drives
diskutil list

# Get more info about USB
diskutil info /dev/disk2
```

## Next: Play Store & App Store

When you're ready to distribute:
- **Android**: Use `app-release.aab` for Google Play Console
- **iOS**: Requires TestFlight setup (add iOS signing to workflow)

---

**Your current commit:** `b21628c` (Track menu system)  
**Status:** Ready to build! Push to GitHub and watch it compile. ✨
