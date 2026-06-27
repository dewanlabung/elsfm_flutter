# Quick Start: Phase 1 Testing

## Installation Complete? ✅

The APK has been installed to your Android device at: **RF9XA017X8P**

---

## Test in 3 Steps

### Step 1: Open App & Enable Dev Mode (30 seconds)

1. **Tap app icon** → ELSFM opens
2. **Scroll to bottom** of login screen
3. **Tap "Dev Mode" toggle** (you'll see the construction icon)
4. ✅ **Confirm:** Toggle shows green checkmark, toast says "✓ Dev mode ON"

---

### Step 2: Auto-Login Works (1 minute)

1. **Close the app completely** (swipe up in recent apps or: `adb shell pm clear com.example.elsfm_flutter`)
2. **Reopen the app** from home/app drawer
3. ✅ **Verify:** App skips login screen and shows channels/home screen
4. ✅ **Verify:** You're logged in (no login screen appears)

---

### Step 3: Verify 200 Response (2 minutes)

This is the critical fix - checking that `/channel` returns **200** instead of **403**.

**Terminal on your computer:**

```bash
# Clear and monitor logs
~/Library/Android/sdk/platform-tools/adb -s RF9XA017X8P logcat -c

# Start capturing logs (let it run in background)
~/Library/Android/sdk/platform-tools/adb -s RF9XA017X8P logcat > /tmp/logcat.log &
LOGCAT_PID=$!

# Give it 5 seconds to capture
sleep 5

# Stop logging
kill $LOGCAT_PID
wait 2>/dev/null

# Check for success response
grep -i "channel\|200\|403" /tmp/logcat.log | tail -20
```

✅ **Expected:** Should see `200` (success), NOT `403` (forbidden)

---

## What You Should See

### Dev Mode Toggle
- Construction icon 🏗️ when OFF
- Green checkmark ✅ when ON
- Shows email: `live.elsfm@gmail.com`

### After Restarting App
- Skips login screen completely
- Shows channel list directly
- You're logged in automatically

### In Logcat
- Should NOT see: `"403 Forbidden"` or `"You don't have required permissions"`
- Should see HTTP response with `200` status code

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Dev mode toggle doesn't appear | Scroll down to bottom of login screen |
| Auto-login doesn't work | Make sure toggle is GREEN before closing app |
| Still seeing 403 error | Ensure you have the latest APK (just installed) |
| Logcat shows nothing | Run `adb logcat -c` first, then trigger the endpoint |

---

## Next: What to Report Back

After testing, tell me:

1. ✅ Dev mode toggle works? (yes/no)
2. ✅ Auto-login works? (yes/no)  
3. ✅ Logcat shows 200 (not 403)? (yes/no)
4. 📝 Any error messages?

Then we can proceed to **Phase 2: Google Sign-In + Password Saving** 🚀

---

## Reference Commands

```bash
# Check device is connected
~/Library/Android/sdk/platform-tools/adb devices

# View live logcat (Ctrl+C to stop)
~/Library/Android/sdk/platform-tools/adb -s RF9XA017X8P logcat

# Clear app cache and restart
~/Library/Android/sdk/platform-tools/adb -s RF9XA017X8P shell pm clear com.example.elsfm_flutter
~/Library/Android/sdk/platform-tools/adb -s RF9XA017X8P shell am start -n com.example.elsfm_flutter/com.example.elsfm_flutter.MainActivity

# Uninstall app
~/Library/Android/sdk/platform-tools/adb -s RF9XA017X8P uninstall com.example.elsfm_flutter

# Check app version
~/Library/Android/sdk/platform-tools/adb -s RF9XA017X8P shell dumpsys package com.example.elsfm_flutter | grep versionName
```

---

## Need Help?

See detailed guide: `docs/TESTING_PHASE_1.md`
