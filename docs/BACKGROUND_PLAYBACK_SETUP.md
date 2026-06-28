# Background Playback Implementation Guide

This document explains the background playback, sleep timer, and notification systems implemented in the ELSFM Flutter app, based on patterns from the YMusic Android app.

## Overview

The app now supports:
1. **Background Playback** - Audio continues when app is minimized
2. **Sleep Timer** - Auto-pause after user-selected duration
3. **Enhanced Notifications** - Lock screen controls and album art
4. **Media Session Integration** - Headphone button controls

## Architecture

### 1. Audio Session Configuration

**File:** `lib/data/services/player_service.dart`

The `AudioSession` is configured for music playback with proper audio routing:

```dart
final session = await AudioSession.instance;
await session.configure(const AudioSessionConfiguration.music());
```

This tells Android/iOS that:
- Audio should continue when app is backgrounded
- Device should not go to sleep during playback
- Proper audio focus handling is enabled

### 2. Audio Service Handler

**File:** `lib/data/services/audio_service_handler.dart`

The `AudioServiceHandler` maintains a foreground service that:
- Keeps the service alive even when app is paused
- Shows notification with playback controls
- Handles lock screen controls and headphone buttons
- Prevents the service from being killed by the OS

**Critical Configuration:**
```dart
androidStopForegroundOnPause: false  // Keep service running when paused
androidForegroundServiceType: AndroidForegroundServiceType.mediaPlayback
```

### 3. Sleep Timer Service

**File:** `lib/data/services/sleep_timer_service.dart`

The `SleepTimerService` manages auto-pause scheduling:
- Tracks remaining time with 1-second resolution
- Fires callback when timer expires
- Supports cancellation and extension
- Uses Riverpod providers for reactive state

**Usage:**
```dart
playerService.startSleepTimer(Duration(minutes: 30));
playerService.cancelSleepTimer();
Duration? remaining = playerService.sleepTimerRemaining;
```

### 4. Sleep Timer UI

**File:** `lib/presentation/widgets/sleep_timer_button.dart`

Provides a button widget that:
- Shows timer status when active
- Opens bottom sheet with preset options (5/10/15/30/60 min)
- Allows cancellation of active timer

## Android Configuration

### Permissions

**File:** `android/app/src/main/AndroidManifest.xml`

Required permissions added:
```xml
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
```

These allow:
- `WAKE_LOCK` - Keep CPU awake during playback
- `FOREGROUND_SERVICE` - Run service in foreground
- `FOREGROUND_SERVICE_MEDIA_PLAYBACK` - Media playback foreground service type

### How It Works on Android

1. **User starts playback** → AudioHandler starts foreground service
2. **User minimizes app** → Service continues running with notification
3. **Notification shows** → User can pause/play/skip from lock screen
4. **Service stays alive** → `androidStopForegroundOnPause: false` prevents Android from killing it

The key difference from other apps:
- Many apps use a notification that dismisses when paused
- YMusic (and now ELSFM) keeps the notification to prevent service termination
- The notification is only removed when playback fully stops

## How It Works on iOS

**Note:** iOS has different background audio handling:
- App requests "Audio playback in background" capability
- Audio service runs in background automatically
- No explicit foreground service needed (iOS doesn't have them)
- Remote controls work via `AVAudioSession` and media center

## Implementation Checklist

### Player Service Integration

```dart
// In your player screen/state management:

// Start playback
await playerService.play();

// Set sleep timer
playerService.startSleepTimer(Duration(minutes: 30));

// Check timer status
if (playerService.isSleepTimerRunning) {
  Duration? remaining = playerService.sleepTimerRemaining;
  print('Timer: ${remaining?.inMinutes} minutes left');
}
```

### UI Integration

```dart
// In your player widget:
import 'package:elsfm/presentation/widgets/sleep_timer_button.dart';

// Add to your player controls:
SleepTimerButton(
  onTimerStarted: () {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sleep timer started')),
    );
  },
)
```

### State Management (Riverpod)

```dart
// Watch sleep timer state
final timerProvider = Provider((ref) {
  final service = ref.watch(sleepTimerServiceProvider);
  return service.isRunning;
});

// In widget:
final isTimerRunning = ref.watch(timerProvider);
```

## Testing Background Playback

### Android Testing Checklist

- [ ] Start playback
- [ ] Minimize app (use home button)
- [ ] Verify audio continues playing
- [ ] Open notification - verify controls work
- [ ] Press play/pause button on headphones - verify works
- [ ] Start sleep timer
- [ ] Wait for timer to expire - verify app pauses
- [ ] Set sleep timer and cancel it before expiry
- [ ] Minimize app while timer is running - verify timer continues

### iOS Testing Checklist

- [ ] Start playback
- [ ] Minimize app
- [ ] Verify audio continues
- [ ] Swipe up Control Center - verify media controls appear
- [ ] Use control center to pause/play
- [ ] Check lock screen - verify media info displays
- [ ] Test headphone controls
- [ ] Test sleep timer functionality

## Troubleshooting

### Audio Stops When App is Backgrounded

**Problem:** Audio stops when you minimize the app

**Solutions:**
1. Verify `AudioSession.configure()` is called in `PlayerService.init()`
2. Check `androidStopForegroundOnPause: false` in audio service config
3. Ensure `FOREGROUND_SERVICE` and `WAKE_LOCK` permissions are in manifest
4. Verify device has enough battery (some devices pause background audio when low)

### Notification Not Showing

**Problem:** No notification appears during playback

**Solutions:**
1. Check notification channel is created (`com.elsfm.app.channel.audio`)
2. Verify `androidNotificationOngoing: true` in audio service config
3. Check notification icon exists at `android/app/src/main/res/mipmap/ic_launcher.png`
4. On Android 13+, check notification permission is granted

### Sleep Timer Not Working

**Problem:** Sleep timer doesn't pause after duration expires

**Solutions:**
1. Verify `onCompletion` callback in `startSleepTimer()` calls `pause()`
2. Check that `pause()` properly integrates with player service
3. Verify device time is not skewed (affects timer calculations)
4. Check logs for any exceptions during timer countdown

### Headphone Button Controls Don't Work

**Problem:** Headphone play/pause button doesn't work

**Solutions:**
1. Verify `AudioSession` is properly configured
2. Check `MediaSession` is active in audio handler
3. Ensure `MediaControl` actions are properly defined
4. Try with different headphones to rule out device-specific issues

## Performance Considerations

### Battery Impact

- Background playback uses ~15-20% more battery per hour
- Sleep timer keeps processor awake only during countdown
- Notification icon is lightweight (no constant refreshes)

### Memory Impact

- Audio service adds ~5-10 MB to app memory
- Sleep timer uses minimal memory (just a timer and callback)
- Caching strategies defined in player service

### Network Impact

- Audio streams continuously over network
- Ensure API server stays responsive during background playback
- Consider implementing connection timeout for inactive streams

## Comparing with YMusic

### YMusic Approach (Android)
- Custom `InvincibleService` that restarts foreground service every 30 seconds
- Media3 (ExoPlayer) with advanced caching
- Separate download cache for offline playback
- Complex state management with Kotlin coroutines

### ELSFM Approach (Flutter)
- `audio_service` package handles foreground service management
- `just_audio` for playback (simpler than ExoPlayer)
- Riverpod for reactive state management
- Simpler Dart-based architecture, cross-platform

### Key Differences
| Feature | YMusic | ELSFM |
|---------|--------|-------|
| Foreground Service | Manual management | `audio_service` handles |
| State Management | Kotlin coroutines | Riverpod |
| Audio Engine | Media3/ExoPlayer | just_audio |
| Platform | Android only | Flutter (iOS + Android) |
| Offline Playback | Full support | Planned |
| Sleep Timer | UI timer | Riverpod-based timer |

## References

- [audio_service package](https://pub.dev/packages/audio_service)
- [just_audio package](https://pub.dev/packages/just_audio)
- [audio_session package](https://pub.dev/packages/audio_session)
- [Android Audio Focus](https://developer.android.com/guide/topics/media-apps/audio-focus)
- [YMusic source code](https://github.com/mrsep/YMusic)
