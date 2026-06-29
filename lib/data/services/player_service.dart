import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
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
  void setAuthToken(String? token) => _authToken = token;

  /// Constructs the stream URL for a track.
  ///
  /// BeMusic serves audio at `{apiBaseUrl}/tracks/{id}/stream`. The URL is
  /// consumed directly by just_audio; no redirect or JSON response is expected.
  String _streamUrl(int trackId) {
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
    // The /play endpoint redirects to storage. If the server APP_URL is http://
    // the redirect will be HTTP. We normalise to HTTPS here so that when the
    // server is eventually updated, we don't need an app release.
    // Android network_security_config also permits cleartext for elsfm.com as
    // a fallback while the server still serves http:// storage URLs.
    return '$base/tracks/$trackId/play'.replaceFirst('http://', 'https://');
  }

  Map<String, String> get _authHeaders => {
    'Accept': '*/*',
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
    _tracksList = List<Track>.from(tracks);
    await _playlist.clear();
    for (final track in tracks) {
      await _playlist.add(
        AudioSource.uri(
          Uri.parse(_streamUrl(track.id)),
          headers: _authHeaders,
        ),
      );
    }
  }

  /// Returns an unmodifiable view of the current queue.
  List<Track> get queue => List.unmodifiable(_tracksList);

  Future<void> play() => _audioPlayer.play();
  Future<void> pause() async {
    _sleepTimer.cancelTimer();
    await _audioPlayer.pause();
  }

  Future<void> stop() => _audioPlayer.stop();

  Future<void> seek(Duration position) => _audioPlayer.seek(position);
  Future<void> previous() => _audioPlayer.seekToPrevious();
  Future<void> next() => _audioPlayer.seekToNext();

  Future<void> setPlaybackRate(double rate) => _audioPlayer.setSpeed(rate);

  Future<void> setLoopMode(LoopMode mode) => _audioPlayer.setLoopMode(mode);

  /// Enables or disables shuffle. When enabling, rebuilds the playlist from a
  /// shuffled copy so the original [_tracksList] order is preserved for
  /// when shuffle is later disabled.
  Future<void> setShuffle(bool shuffle) async {
    if (shuffle) {
      final shuffled = List<Track>.from(_tracksList)..shuffle();
      await _playlist.clear();
      for (final track in shuffled) {
        await _playlist.add(
          AudioSource.uri(Uri.parse(_streamUrl(track.id)), headers: _authHeaders),
        );
      }
    } else {
      // Rebuild playlist in original order
      await _playlist.clear();
      for (final track in _tracksList) {
        await _playlist.add(
          AudioSource.uri(Uri.parse(_streamUrl(track.id)), headers: _authHeaders),
        );
      }
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

  Stream<String?> get errorStream => _errorController.stream;

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
