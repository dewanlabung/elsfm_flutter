import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';
import 'package:elsfm/data/models/track.dart';

/// Audio streaming service that handles stream URL fetching and playback
class AudioStreamingService {
  final Dio dio;
  final AudioPlayer audioPlayer = AudioPlayer();

  AudioStreamingService({required this.dio});

  /// Builds the best URL for streaming a track.
  /// Uses /download endpoint (same as the WordPress plugin) which works
  /// without browser session auth. Token passed as query param too because
  /// ExoPlayer strips the Authorization header when following HTTP redirects.
  String buildStreamUrl(int trackId) {
    final baseUrl = dio.options.baseUrl.replaceAll(RegExp(r'/$'), '');
    final authHeader = dio.options.headers['Authorization'] as String?;
    final token = authHeader?.replaceFirst('Bearer ', '');
    return token != null
        ? '$baseUrl/tracks/$trackId/download?token=$token'
        : '$baseUrl/tracks/$trackId/download';
  }

  Future<void> loadTrack({
    required Track track,
    String quality = 'high',
  }) async {
    try {
      // Use resolved storage URL from track.src if available
      final src = track.src;
      final String url;
      if (src.startsWith('https://') || src.startsWith('http://')) {
        url = src;
      } else {
        url = buildStreamUrl(track.id);
      }

      final uri = Uri.tryParse(url);
      if (uri == null || uri.scheme != 'https' || uri.host != 'www.elsfm.com') {
        throw AudioStreamException('Invalid or untrusted stream URL: $url');
      }

      final authHeader = dio.options.headers['Authorization'] as String?;
      final headers = <String, String>{
        'Accept': 'audio/*,*/*',
        if (authHeader != null) 'Authorization': authHeader,
      };

      await audioPlayer.setAudioSource(
        AudioSource.uri(uri, headers: headers),
      );
    } on AudioStreamException {
      rethrow;
    } catch (e) {
      throw AudioStreamException('Failed to load track: $e');
    }
  }

  /// Play the loaded track
  Future<void> play() async {
    try {
      await audioPlayer.play();
    } catch (e) {
      throw AudioStreamException('Playback failed: $e');
    }
  }

  /// Pause playback
  Future<void> pause() async {
    try {
      await audioPlayer.pause();
    } catch (e) {
      throw AudioStreamException('Pause failed: $e');
    }
  }

  /// Seek to position in current track
  Future<void> seek(Duration position) async {
    try {
      await audioPlayer.seek(position);
    } catch (e) {
      throw AudioStreamException('Seek failed: $e');
    }
  }

  /// Set playback speed
  Future<void> setSpeed(double speed) async {
    try {
      if (speed < 0.5 || speed > 2.0) {
        throw AudioStreamException('Speed must be between 0.5 and 2.0');
      }
      await audioPlayer.setSpeed(speed);
    } catch (e) {
      throw AudioStreamException('Failed to set speed: $e');
    }
  }

  /// Get current duration
  Duration? getDuration() => audioPlayer.duration;

  /// Get current position
  Stream<Duration> getPositionStream() => audioPlayer.positionStream;

  /// Get playback state stream
  Stream<PlayerState> getPlayerStateStream() => audioPlayer.playerStateStream;

  /// Check if currently playing
  bool get isPlaying =>
      audioPlayer.playerState.playing && audioPlayer.playerState.processingState != ProcessingState.completed;

  /// Get current position
  Duration get currentPosition => audioPlayer.position;

  /// Stop playback and release resources
  Future<void> stop() async {
    try {
      await audioPlayer.stop();
    } catch (e) {
      throw AudioStreamException('Failed to stop playback: $e');
    }
  }

  /// Dispose of resources
  Future<void> dispose() async {
    try {
      await audioPlayer.dispose();
    } catch (e) {
      throw AudioStreamException('Cleanup failed: $e');
    }
  }
}

/// Audio streaming exception
class AudioStreamException implements Exception {
  final String message;

  AudioStreamException(this.message);

  @override
  String toString() => 'AudioStreamException: $message';
}
