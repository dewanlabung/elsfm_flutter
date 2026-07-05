import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/player_state.dart' as ps;
import '../models/track.dart';
import 'audio_service_handler.dart';
import 'sleep_timer_service.dart';
import '../../config/app_config.dart';

class PlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late ConcatenatingAudioSource _playlist;
  AudioHandler? _audioHandler;
  final SleepTimerService _sleepTimer = SleepTimerService();
  List<Track> _tracksList = [];
  late final StreamController<String?> _errorController =
      StreamController<String?>.broadcast();

  /// Optional Bearer token forwarded to just_audio for authenticated streaming.
  String? _authToken;

  /// Update the auth token used for stream requests. Call this after login.
  void setAuthToken(String? token) {
    _authToken = token;
    if (kDebugMode) {
      debugPrint('[PlayerService] Auth token updated: ${token != null ? '${token.substring(0, 20)}...' : 'null'}');
    }
  }

  /// Resolves the direct CDN URL for a track's audio file.
  ///
  /// BeMusic API returns src as "storage/track_media/xxx.mp3" (relative path).
  /// Build the full HTTPS URL — matching exactly how elsfm-native does it:
  ///   MediaItem.Builder().setUri(baseUrl + src)  // no auth headers
  ///
  /// Confirmed: https://www.elsfm.com/storage/track_media/xxx.mp3
  ///   → HTTP 200, Content-Type: audio/mpeg, Accept-Ranges: bytes (public static file)
  String _resolveAudioUrl(Track track) {
    final src = track.src.trim();
    if (src.isNotEmpty) {
      if (src.startsWith('http://') || src.startsWith('https://')) return src;
      final base = AppConfig.webBaseUrl.replaceAll(RegExp(r'/$'), '');
      return '$base/$src';
    }
    // Fallback to stream endpoint when src is absent
    final apiBase = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
    return '$apiBase/tracks/${track.id}/stream';
  }

  AudioSource _buildSource(Track track) {
    final url = _resolveAudioUrl(track);
    // Static CDN files are publicly accessible — sending auth headers causes
    // ExoPlayer "Source error". Only the stream API endpoint needs auth.
    final isStaticStorage = url.contains('/storage/');
    if (kDebugMode) {
      debugPrint('[PlayerService] Track ${track.id} "${track.name}": $url');
      debugPrint('[PlayerService] Headers: ${isStaticStorage ? "none (static)" : "Bearer token"}');
    }
    return AudioSource.uri(
      Uri.parse(url),
      headers: isStaticStorage ? const {} : _authHeaders,
    );
  }

  Map<String, String> get _authHeaders => {
    'Accept': 'audio/*,*/*',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  Future<void> init({List<Track>? tracks}) async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    _playlist = ConcatenatingAudioSource(children: []);
    await _audioPlayer.setAudioSource(_playlist);

    _audioPlayer.playbackEventStream.listen(
      (_) {},
      onError: (Object e, StackTrace st) {
        _errorController.add(e.toString());
      },
    );

    // Initialize audio service for lock screen controls
    if (tracks != null) {
      _tracksList = List<Track>.from(tracks);
    }
    try {
      _audioHandler = await initAudioService(_audioPlayer, tracks: _tracksList);
    } catch (e) {
      // Audio service initialization failure is non-fatal
      // The app continues to work without lock screen controls
    }
  }

  Future<void> setQueue(List<Track> tracks) async {
    if (kDebugMode) debugPrint('[PlayerService] setQueue called with ${tracks.length} tracks');
    _tracksList = List<Track>.from(tracks);
    await _playlist.clear();
    for (final track in tracks) {
      if (kDebugMode) debugPrint('[PlayerService] Adding track: ${track.name} (id: ${track.id}, src: ${track.src})');
      await _playlist.add(_buildSource(track));
    }
    if (kDebugMode) debugPrint('[PlayerService] Queue setup complete');
  }

  /// Returns an unmodifiable view of the current queue.
  List<Track> get queue => List.unmodifiable(_tracksList);

  Future<void> play() async {
    if (kDebugMode) debugPrint('[PlayerService] play() called');
    try {
      await _audioPlayer.play();
      if (kDebugMode) debugPrint('[PlayerService] play() succeeded, state: ${_audioPlayer.playerState}');
    } catch (e) {
      if (kDebugMode) debugPrint('[PlayerService] play() failed: $e');
      rethrow;
    }
  }

  Future<void> pause() async {
    _sleepTimer.cancelTimer();
    if (kDebugMode) debugPrint('[PlayerService] pause() called');
    await _audioPlayer.pause();
  }

  Future<void> stop() async {
    if (kDebugMode) debugPrint('[PlayerService] stop() called');
    await _audioPlayer.stop();
  }

  Future<void> seek(Duration position) async {
    if (kDebugMode) debugPrint('[PlayerService] seek() to ${position.inSeconds}s');
    await _audioPlayer.seek(position);
  }
  Future<void> previous() => _audioPlayer.seekToPrevious();
  Future<void> next() => _audioPlayer.seekToNext();

  Future<void> setPlaybackRate(double rate) => _audioPlayer.setSpeed(rate);

  Future<void> setLoopMode(LoopMode mode) => _audioPlayer.setLoopMode(mode);

  /// Enables or disables shuffle. When enabling, rebuilds the playlist from a
  /// shuffled copy so the original [_tracksList] order is preserved for
  /// when shuffle is later disabled.
  Future<void> setShuffle(bool shuffle) async {
    final list = shuffle
        ? (List<Track>.from(_tracksList)..shuffle())
        : _tracksList;
    await _playlist.clear();
    for (final track in list) {
      await _playlist.add(_buildSource(track));
    }
  }

  Stream<ps.PlayerState> get playerStateStream {
    return _audioPlayer.playerStateStream.map((state) {
      return ps.PlayerState(
        queue: [],
        isPlaying: state.playing,
        isLoading: state.processingState == ProcessingState.loading,
      );
    });
  }

  // just_audio surfaces errors as PlayerState with processingState == idle
  // after a failed load. Map this to an error string for the UI.
  Stream<String?> get errorStream {
    return _audioPlayer.playerStateStream.map((s) {
      if (!s.playing && s.processingState == ProcessingState.idle) {
        // idle after a load attempt usually means the source failed
        return null; // distinguish from "never started" with null here;
                     // PlaybackException is thrown on play() and caught in notifier
      }
      return null;
    }).distinct();
  }

  Stream<int?> get currentIndexStream => _audioPlayer.currentIndexStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;

  AudioPlayer get audioPlayer => _audioPlayer;
  AudioHandler? get audioHandler => _audioHandler;
  SleepTimerService get sleepTimer => _sleepTimer;

  /// Start a sleep timer that will auto-pause after [duration].
  ///
  /// [duration] - How long until playback pauses (e.g., Duration(minutes: 5))
  void startSleepTimer(Duration duration) {
    _sleepTimer.startTimer(
      duration: duration,
      onComplete: () {
        pause();
      },
    );
  }

  /// Cancel the active sleep timer.
  void cancelSleepTimer() {
    _sleepTimer.cancelTimer();
  }

  /// Get remaining time on the sleep timer, or null if not running.
  Duration? get sleepTimerRemaining => _sleepTimer.remainingTime;

  /// Check if sleep timer is running.
  bool get isSleepTimerRunning => _sleepTimer.isRunning;

  Future<void> dispose() async {
    _sleepTimer.cancelTimer();
    if (_audioHandler != null) {
      await _audioHandler!.stop();
    }
    await _audioPlayer.dispose();
    await _errorController.close();
  }
}
