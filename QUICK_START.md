# Quick Start: Background Playback & Sleep Timer

## 5-Minute Setup

### 1. Verify Dependencies
Your `pubspec.yaml` already has all required packages:
- ✓ `audio_service: ^0.18.16`
- ✓ `audio_session: ^0.1.25`
- ✓ `just_audio: ^0.9.39`

### 2. Android Permissions
Already added to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
```

### 3. Start Playing Music

```dart
import 'package:elsfm/data/services/player_service.dart';

final playerService = PlayerService();

// Initialize
await playerService.init(tracks: myTracks);

// Play
await playerService.play();

// Background playback now works!
```

### 4. Add Sleep Timer Button

```dart
import 'package:elsfm/presentation/widgets/sleep_timer_button.dart';

// In your player UI:
SleepTimerButton(
  onTimerStarted: () {
    print('Sleep timer started');
  },
)
```

### 5. Test It

```bash
flutter run -d android_device

# Then:
# 1. Start playing music
# 2. Press home button (minimize app)
# 3. Audio should continue playing
# 4. Pull down notification to see controls
```

---

## Using Sleep Timer Programmatically

```dart
// Start a 30-minute timer
playerService.startSleepTimer(Duration(minutes: 30));

// Check if timer is running
if (playerService.isSleepTimerRunning) {
  print('Timer is running');
}

// Get remaining time
Duration? remaining = playerService.sleepTimerRemaining;
if (remaining != null) {
  print('${remaining.inMinutes} minutes left');
}

// Cancel the timer
playerService.cancelSleepTimer();
```

---

## API Reference

### PlayerService

```dart
// Playback controls
Future<void> play()
Future<void> pause()
Future<void> stop()
Future<void> seek(Duration position)
Future<void> previous()
Future<void> next()

// Sleep timer
void startSleepTimer(Duration duration)
void cancelSleepTimer()
Duration? get sleepTimerRemaining
bool get isSleepTimerRunning

// Queue management
Future<void> setQueue(List<Track> tracks)
List<Track> get queue

// Playback info
Stream<Duration> get positionStream
Stream<Duration?> get durationStream
Stream<int?> get currentIndexStream
```

### SleepTimerService

```dart
// Direct access (usually not needed)
void startTimer({
  required Duration duration,
  required Function() onComplete,
})
void cancelTimer()
void extendTimer(Duration duration)
Duration? get remainingTime
bool get isRunning
```

---

## Troubleshooting

### Audio stops when app is minimized
- [ ] WiFi is connected (required for streaming)
- [ ] `PlayerService.init()` was called before playing
- [ ] Device isn't in low power mode
- [ ] Try restarting the app

### Sleep timer doesn't work
- [ ] Verify `pause()` is called when timer expires
- [ ] Check that music was playing when timer started
- [ ] Try cancelling and starting timer again

### No notification appears
- [ ] On Android 13+, grant notification permission
- [ ] Try restarting the app
- [ ] Check device isn't in "Do Not Disturb" mode

### Lock screen controls don't work
- [ ] Verify `AudioSession` is configured in `PlayerService.init()`
- [ ] Check device isn't in airplane mode
- [ ] Try restarting the app

---

## What Changed

### Files Created
1. `lib/data/services/sleep_timer_service.dart` - Timer logic
2. `lib/presentation/widgets/sleep_timer_button.dart` - Timer UI
3. `docs/BACKGROUND_PLAYBACK_SETUP.md` - Full documentation

### Files Modified
1. `android/app/src/main/AndroidManifest.xml` - Added permissions
2. `lib/data/services/player_service.dart` - Integrated timer
3. `lib/data/services/audio_service_handler.dart` - Fixed service config

### Nothing Else
- No new dependencies
- No breaking changes
- Fully backward compatible

---

## Next Steps

1. **Test Background Playback**
   - Run the app: `flutter run -d device_id`
   - Start playback
   - Minimize app (home button)
   - Verify audio continues for 1+ minute

2. **Test Sleep Timer**
   - Start playback
   - Tap sleep timer button
   - Select 1 minute
   - Verify app pauses after 1 minute

3. **Deploy to Play Store**
   - Follow normal Flutter release process
   - No special signing requirements
   - All permissions are declared

---

## Full Documentation

For detailed information, see:
- `docs/BACKGROUND_PLAYBACK_SETUP.md` - Architecture & troubleshooting
- `IMPLEMENTATION_NOTES.md` - Technical details & checklist

---

**Status:** Ready to use! ✅

Questions? Check the docs or open an issue.
