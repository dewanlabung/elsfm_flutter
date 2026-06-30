import 'package:audio_players/audio_players.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import '../models/player_state.dart' as ps;
import '../models/track.dart';
import 'audio_service_handler.dart';
import 'sleep_timer_service.dart';
import '../../config/app_config.dart';

class PlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  AudioHandler? _audioHandler;
  final SleepTimerService _sleepTimer = SleepTimerService();
  List<Track> _tracksList = [];
  int _currentIndex = 0;

  /// Optional Bearer token forwarded to audio_players for authenticated streaming.
  String? _authToken;

  /// Update the auth token used for stream requests. Call this after login.
  void setAuthToken(String? token) {
    _authToken = token;
    if (kDebugMode) {
      debugPrint('[PlayerService] Auth token updated: ${token != null ? '${token.substring(0, 20)}...' : 'null'}');
    }
  }

  /// Builds the best URL for streaming a track.
  /// Priority:
  ///  1. track.src is already a full resolved URL (e.g. storage URL from API)
  ///  2. BeMusic's /download endpoint with token as query param
  String _buildStreamUrl(Track track) {
    final src = track.src;

    // Option 1: resolved storage URL (set in Track.fromJson from the API's src field)
    if (src.startsWith('https://') || src.startsWith('http://')) {
      if (kDebugMode) {
        debugPrint('[PlayerService] Using direct URL: $src');
      }
      return src;
    }

    // Option 2: BeMusic /download endpoint with token as query param
    // Token in query param because some servers strip Authorization header on redirect
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
    final downloadUrl = _authToken != null
        ? '$base/tracks/${track.id}/download?token=$_authToken'
        : '$base/tracks/${track.id}/download';

    if (kDebugMode) {
      debugPrint('[PlayerService] Using /download endpoint: $downloadUrl');
    }
    return downloadUrl;
  }

  Map<String, String> get _authHeaders => {
    'Accept': 'audio/*,*/*',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  Future<void> init({List<Track>? tracks}) async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Listen to player events
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (kDebugMode) debugPrint('[PlayerService] Player state: $state');
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (kDebugMode) debugPrint('[PlayerService] Duration: ${duration.inSeconds}s');
    });

    _audioPlayer.onPositionChanged.listen((position) {
      // Log periodically, not every update
    });

    // Initialize audio service for lock screen controls
    if (tracks != null) {
      _tracksList = List<Track>.from(tracks);
    }
    try {
      _audioHandler = await initAudioService(_audioPlayer, tracks: _tracksList);
    } catch (e) {
      // Audio service initialization failure is non-fatal
      if (kDebugMode) debugPrint('[PlayerService] Audio service init failed: $e');
    }
  }

  /// Set the queue and optionally start playing
  Future<void> setQueue(List<Track> tracks, {int startIndex = 0}) async {
    if (kDebugMode) debugPrint('[PlayerService] setQueue called with ${tracks.length} tracks, startIndex: $startIndex');

    _tracksList = List<Track>.from(tracks);
    _currentIndex = startIndex;

    if (_tracksList.isEmpty) {
      if (kDebugMode) debugPrint('[PlayerService] Queue is empty');
      return;
    }

    // Load the first track (or startIndex track)
    final track = _tracksList[_currentIndex];
    final url = _buildStreamUrl(track);

    if (kDebugMode) {
      debugPrint('[PlayerService] Loading track: ${track.name} from $url');
    }

    try {
      await _audioPlayer.setSource(UrlSource(url));
      if (kDebugMode) debugPrint('[PlayerService] Queue setup complete');
    } catch (e) {
      if (kDebugMode) debugPrint('[PlayerService] Failed to load track: $e');
      rethrow;
    }
  }

  /// Returns an unmodifiable view of the current queue.
  List<Track> get queue => List.unmodifiable(_tracksList);

  Future<void> play() async {
    if (kDebugMode) debugPrint('[PlayerService] play() called');
    try {
      await _audioPlayer.play(AssetSource('')); // Resume playback
      if (kDebugMode) debugPrint('[PlayerService] play() succeeded');
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

  Future<void> previous() async {
    if (_currentIndex > 0) {
      _currentIndex--;
      if (_tracksList.isNotEmpty) {
        final track = _tracksList[_currentIndex];
        final url = _buildStreamUrl(track);
        await _audioPlayer.setSource(UrlSource(url));
        await play();
      }
    }
  }

  Future<void> next() async {
    if (_currentIndex < _tracksList.length - 1) {
      _currentIndex++;
      final track = _tracksList[_currentIndex];
      final url = _buildStreamUrl(track);
      await _audioPlayer.setSource(UrlSource(url));
      await play();
    }
  }

  Future<void> setPlaybackRate(double rate) => _audioPlayer.setPlaybackRate(rate);

  Future<void> setLoopMode(LoopMode mode) => _audioPlayer.setReleaseMode(
    mode == LoopMode.all ? ReleaseMode.loop : ReleaseMode.release,
  );

  /// Enables or disables shuffle (basic implementation)
  Future<void> setShuffle(bool shuffle) async {
    if (shuffle && _tracksList.length > 1) {
      final shuffled = List<Track>.from(_tracksList)..shuffle();
      await setQueue(shuffled);
    } else {
      await setQueue(_tracksList);
    }
  }

  Stream<ps.PlayerState> get playerStateStream {
    return _audioPlayer.onPlayerStateChanged.map((state) {
      return ps.PlayerState(
        queue: [],
        isPlaying: state == PlayerState.playing,
        isLoading: state == PlayerState.playing,
      );
    });
  }

  Stream<String?> get errorStream {
    return _audioPlayer.onPlayerComplete.map((_) => null);
  }

  Stream<int?> get currentIndexStream {
    return Stream.value(_currentIndex);
  }

  Stream<Duration> get positionStream {
    return _audioPlayer.onPositionChanged.map((duration) => duration);
  }

  Stream<Duration?> get durationStream {
    return _audioPlayer.onDurationChanged.map((duration) => duration);
  }

  AudioPlayer get audioPlayer => _audioPlayer;
  AudioHandler? get audioHandler => _audioHandler;
  SleepTimerService get sleepTimer => _sleepTimer;

  /// Get current position
  Duration get currentPosition => _audioPlayer.currentPosition;

  /// Start a sleep timer that will auto-pause after [duration].
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
    await _audioPlayer.release();
  }
}
