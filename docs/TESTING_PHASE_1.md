# Testing Phase 1: Dev-Mode Auto-Login

## What You're Testing

Verification that the dev-mode auto-login feature works and that the channels endpoint now returns **200** (success) instead of **403** (forbidden).

## Setup

### Prerequisites

- Android device or emulator with internet access
- APK built from latest code (commit 4145956+)
- Device connected via adb

### Installation

```bash
# Install the debug APK to device
adb -s <DEVICE_ID> install build/app/outputs/flutter-apk/app-debug.apk

# Or to overwrite existing installation
adb -s <DEVICE_ID> install -r build/app/outputs/flutter-apk/app-debug.apk

# Get your device ID
adb devices
```

---

## Test Procedure

### Test 1: Dev Mode Toggle Appears

1. **Open the app** on your device
2. **Look at login screen**
3. **Scroll down** to bottom
4. ✅ **Verify:** "Dev Mode" toggle appears with construction icon and "Tap to enable quick test login"

---

### Test 2: Enable Dev Mode

1. **Tap the "Dev Mode" toggle** at bottom of login screen
2. **Watch for green indicator** and checkmark icon
3. **Read the credential email:** Should show `live.elsfm@gmail.com`
4. ✅ **Verify:** Toast shows "✓ Dev mode ON - auto-login enabled"

---

### Test 3: Auto-Login on Restart

1. **Dev mode enabled** (from Test 2)
2. **Close the app completely** (swipe it away or kill process):
   ```bash
   adb -s <DEVICE_ID> shell pm pm com.example.elsfm_flutter
   # Or swipe the app away in recent apps
   ```
3. **Reopen the app** from home screen or app drawer
4. ✅ **Verify:** App skips login screen and goes directly to home/channels screen
5. ✅ **Verify:** You're logged in (user profile appears somewhere on screen)

---

### Test 4: Channels Endpoint Returns 200

This is the critical test - verifying the fix for the 403 error.

#### Setup Logcat Monitoring

```bash
# Clear previous logs
adb -s <DEVICE_ID> logcat -c

# Start fresh log capture
adb -s <DEVICE_ID> logcat > /tmp/logcat_phase1.log &
LOGCAT_PID=$!
```

#### Trigger the Test

1. **Device has dev mode enabled** (from Test 2)
2. **Clear app cache:**
   ```bash
   adb -s <DEVICE_ID> shell pm clear com.example.elsfm_flutter
   ```
3. **Restart app:**
   ```bash
   adb -s <DEVICE_ID> shell am start -n com.example.elsfm_flutter/com.example.elsfm_flutter.MainActivity
   ```
4. **Wait 5 seconds** for app to initialize
5. **Stop logcat:**
   ```bash
   kill $LOGCAT_PID
   wait $LOGCAT_PID 2>/dev/null
   ```

#### Check the Result

```bash
# Look for channel endpoint response
grep -i "channel\|/channel" /tmp/logcat_phase1.log | grep -E "200|403"

# Or look for Dio response
grep -i "dio\|response" /tmp/logcat_phase1.log | grep -E "channel|200|403"
```

✅ **Expected Output:** Should contain `200` (success), NOT `403` (forbidden)

---

### Test 5: Disable Dev Mode

1. **Dev mode currently enabled**
2. **Tap the Dev Mode toggle** again
3. ✅ **Verify:** Icon changes to construction, checkmark disappears
4. ✅ **Verify:** Toast shows "✗ Dev mode OFF"
5. **Close and reopen app**
6. ✅ **Verify:** App shows login screen (dev mode is disabled)

---

### Test 6: Manual Login Still Works

1. **Dev mode is OFF**
2. **Email field:** Enter `live.elsfm@gmail.com`
3. **Password field:** Enter `457862@aAa`
4. **Tap "Login with Email"** button
5. ✅ **Verify:** Button shows loading spinner
6. ✅ **Verify:** After 2-3 seconds, you're logged in and see channels
7. ✅ **Verify:** No 403 error appears

---

## Success Criteria

All tests pass when:

- ✅ Dev Mode toggle appears on login screen
- ✅ Dev Mode can be enabled/disabled
- ✅ App auto-logs in after enabling dev mode and restarting
- ✅ Channels endpoint returns 200 (visible in logcat or successful load)
- ✅ No 403 Forbidden errors appear
- ✅ Manual login still works without dev mode
- ✅ App navigates to home/channels screen after successful auth

---

## Logcat Filtering Tips

### View all HTTP responses

```bash
adb logcat | grep -i "response\|http\|200\|403"
```

### View Dio logs specifically

```bash
adb logcat | grep -i "dio"
```

### View Flutter logs only

```bash
adb logcat | grep "flutter"
```

### Save to file and analyze later

```bash
adb logcat > logcat_$(date +%s).log &
# ... do your testing ...
kill %1
grep "channel\|403\|200" logcat_*.log
```

---

## Troubleshooting

### "Dev Mode toggle doesn't appear"
- Ensure you're scrolled to the bottom of the login screen
- Check that app is freshly installed (not cached)
- Verify code changes are in the APK: `grep -r "DevModeToggle" /tmp/app-debug.apk`

### "App shows 403 error still"
- Verify you've enabled dev mode AND restarted the app
- Check that userId is being passed to `/channel` endpoint
- Look for the userId parameter in the logcat output
- Ensure you're using the latest APK (commit 4145956+)

### "Auto-login doesn't work"
- Verify dev mode is enabled (toggle shows green checkmark)
- Verify app is completely closed (check with `adb shell ps`)
- Check logcat for error messages during login
- Try disabling and re-enabling dev mode

### "Logcat shows nothing"
- Ensure you ran `adb logcat -c` to clear previous logs
- Verify device is connected: `adb devices`
- Try different filter: `adb logcat *:V` shows all logs

---

## Next Steps

**If all tests pass:**
- Phase 1 is verified ✅
- Proceed to Phase 2: Google Sign-In + Password Saving
- Consider adding Firebase setup in parallel

**If tests fail:**
- Check logcat for specific error messages
- Verify device has internet connectivity
- Ensure backend API is responding
- Check that userId is actually in the auth response
