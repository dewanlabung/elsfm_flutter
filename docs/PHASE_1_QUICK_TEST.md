# Phase 1 Quick Test Card

## ⏱️ 5-Minute Test Procedure

### Step 1: Enable Dev Mode (30 sec)
```
1. Open ELSFM app
2. Scroll to BOTTOM of login screen
3. See "Dev Mode" toggle with construction icon
4. TAP the toggle
5. ✅ Verify: Green checkmark + toast says "✓ Dev mode ON"
```

### Step 2: Auto-Login Test (1 min)
```
1. Close app COMPLETELY (swipe up in recent apps)
2. Open app again
3. ✅ Verify: Skips login, goes straight to channels/home
4. ✅ Verify: You're logged in (no login screen)
```

### Step 3: Verify 200 Response (2 min)
```
Terminal on your computer:

# Clear logs
adb -s RF9XA017X8P logcat -c

# Capture logs (runs in background)
adb -s RF9XA017X8P logcat > /tmp/logcat.log &
LOGCAT_PID=$!

# Give it 5 seconds
sleep 5

# Stop logging
kill $LOGCAT_PID

# Check for 200 response
grep -i "channel\|200\|403" /tmp/logcat.log | tail -10
```

**✅ Expected:** See `200` in output (success)  
**❌ Bad:** See `403` in output (forbidden)

---

## 🎯 Test Checklist

- [ ] Dev Mode toggle visible at bottom of login screen
- [ ] Dev Mode toggle has construction icon when OFF
- [ ] Dev Mode toggle becomes GREEN with checkmark when ON
- [ ] Toast message shows "✓ Dev mode ON - auto-login enabled"
- [ ] After closing app, it auto-logs in with live.elsfm@gmail.com
- [ ] No login screen appears after restart
- [ ] Channels load immediately (no 403 error)
- [ ] Logcat shows 200 response (not 403)

---

## 🔧 Troubleshooting

| Issue | Solution |
|-------|----------|
| Dev Mode toggle doesn't appear | Scroll down on login screen |
| Toggle won't turn green | Refresh app cache: `adb shell pm clear com.example.elsfm_flutter` |
| Auto-login doesn't work | Ensure toggle is GREEN before closing app |
| Still see 403 error | Verify you have latest APK (just installed) |
| Logcat shows nothing | Run `adb logcat -c` first to clear |

---

## 📊 Success = All 3 Tests Pass

1. ✅ Dev Mode toggle works
2. ✅ Auto-login on restart works  
3. ✅ Channels endpoint returns 200

---

## 📝 Report Back

After testing, let me know:
- [x] Dev Mode toggle visible?
- [x] Can enable/disable it?
- [x] Auto-login works?
- [x] Logcat shows 200 (not 403)?
- [x] Any error messages?

---

## 🔐 Test Credentials

**Email:** `live.elsfm@gmail.com`  
**Password:** `457862@aAa`

(Only used if dev mode is disabled)

---

## 📚 Full Guide

See `docs/QUICK_START.md` for detailed explanation  
See `docs/TESTING_PHASE_1.md` for comprehensive procedures

---

Ready to test? 🚀
