import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/player_state.dart' as ps;
import '../models/track.dart';
import 'native_player_service.dart';
import 'sleep_timer_service.dart';

/// High-level player service backed by the native Android ExoPlayer (Media3).
///
/// Replaces the previous just_audio implementation that failed with
/// "Source error" when ExoPlayer received auth headers for static CDN files.
///
/// The native layer receives pre-built full HTTPS URLs from [Track.src]:
///   https://www.elsfm.com/storage/track_media/xxx.mp3   (no auth headers)
///
/// All public-facing stream types are identical to the old just_audio
/// implementation so that Riverpod providers and UI widgets are unchanged.
class PlayerService {
  final _native      = NativePlayerService();
  final _sleepTimer  = SleepTimerService();
  List<Track> _tracksList = [];

  // ── Auth token (kept for API calls, not used for audio streaming) ─────────
  String? _authToken;
  void setAuthToken(String? token) {
    _authToken = token;
  }

  // ── Initialise ────────────────────────────────────────────────────────────
  Future<void> init({List<Track>? tracks}) async {
    _native.init();
    if (tracks != null) {
      _tracksList = List<Track>.from(tracks);
      await _native.setQueue(_tracksList);
    }
    if (kDebugMode) debugPrint('[PlayerService] native Media3 player initialised');
  }

  // ── Queue management ──────────────────────────────────────────────────────
  Future<void> setQueue(List<Track> tracks) async {
    if (kDebugMode) {
      debugPrint('[PlayerService] setQueue: ${tracks.length} tracks');
      for (final t in tracks) {
        debugPrint('  track ${t.id} "${t.name}" → ${t.src}');
      }
    }
    _tracksList = List<Track>.from(tracks);
    await _native.setQueue(tracks);
  }

  List<Track> get queue => List.unmodifiable(_tracksList);

  // ── Play / pause / stop ───────────────────────────────────────────────────
  Future<void> play() async {
    if (kDebugMode) debugPrint('[PlayerService] play()');
    await _native.play();
  }

  Future<void> pause() async {
    _sleepTimer.cancelTimer();
    await _native.pause();
  }

  Future<void> stop() async {
    await _native.stop();
  }

  /// Start playback at a specific index in the current queue.
  Future<void> playAtIndex(int index) async {
    if (kDebugMode) debugPrint('[PlayerService] playAtIndex($index)');
    await _native.playAtIndex(index);
  }

  // ── Seek / navigation ─────────────────────────────────────────────────────
  Future<void> seek(Duration position) => _native.seekTo(position);
  Future<void> previous()              => _native.skipPrevious();
  Future<void> next()                  => _native.skipNext();

  // ── Playback options ──────────────────────────────────────────────────────
  Future<void> setPlaybackRate(double rate) => _native.setPlaybackSpeed(rate);

  /// Repeat mode: 0 = off, 1 = one, 2 = all  (matches ExoPlayer constants)
  Future<void> setLoopMode(int mode) => _native.setRepeatMode(mode);

  Future<void> setShuffle(bool shuffle) => _native.setShuffleEnabled(shuffle);

  // ── Streams ───────────────────────────────────────────────────────────────

  /// Combined playing + loading state.
  Stream<ps.PlayerState> get playerStateStream {
    return _native.playerStateStream.map((stateStr) {
      return ps.PlayerState(
        queue:     [],
        isPlaying: _native.isPlaying,
        isLoading: stateStr == 'loading',
      );
    });
  }

  Stream<int?>     get currentIndexStream => _native.currentIndexStream;
  Stream<Duration> get positionStream     => _native.positionStream;
  Stream<Duration?> get durationStream   => _native.durationStream;
  Stream<String?>  get errorStream        => _native.errorStream;

  // ── Sleep timer ───────────────────────────────────────────────────────────
  void startSleepTimer(Duration duration) {
    _sleepTimer.startTimer(duration: duration, onComplete: pause);
  }

  void cancelSleepTimer()           => _sleepTimer.cancelTimer();
  Duration? get sleepTimerRemaining => _sleepTimer.remainingTime;
  bool get isSleepTimerRunning      => _sleepTimer.isRunning;

  // ── Dispose ───────────────────────────────────────────────────────────────
  Future<void> dispose() async {
    _sleepTimer.cancelTimer();
    await _native.dispose();
  }
}
