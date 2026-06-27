import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';
import 'package:elsfm/data/models/track.dart';

/// Audio streaming service that handles stream URL fetching and playback
class AudioStreamingService {
  final Dio dio;
  final AudioPlayer audioPlayer = AudioPlayer();

  AudioStreamingService({required this.dio});

  /// Returns the stream URL for a given track ID.
  ///
  /// The BeMusic stream endpoint (`/tracks/{id}/stream`) is a direct audio
  /// stream — it does NOT return JSON. We construct the full URL here and let
  /// just_audio stream it directly, passing the Authorization header so the
  /// server accepts the authenticated request.
  String buildStreamUrl(int trackId) {
    final baseUrl = dio.options.baseUrl.replaceAll(RegExp(r'/$'), '');
    return '$baseUrl/tracks/$trackId/stream';
  }

  /// Load a track for playback using the stream endpoint.
  ///
  /// Passes the Authorization header from [dio] so authenticated users can
  /// stream tracks without being redirected to the login page.
  Future<void> loadTrack({
    required Track track,
    String quality = 'high',
  }) async {
    try {
      final streamUrl = buildStreamUrl(track.id);

      // Validate the stream URL before passing it to the audio player.
      // Only HTTPS URLs from the trusted elsfm.com host are allowed.
      final uri = Uri.tryParse(streamUrl);
      if (uri == null || uri.scheme != 'https' || uri.host != 'www.elsfm.com') {
        throw AudioStreamException('Invalid or untrusted stream URL: $streamUrl');
      }

      // Forward the Authorization header so just_audio can authenticate.
      final authHeader = dio.options.headers['Authorization'] as String?;
      final headers = <String, String>{
        'Accept': '*/*',
        'User-Agent': dio.options.headers['User-Agent'] as String? ?? '',
        if (authHeader != null) 'Authorization': authHeader,
      };

      await audioPlayer.setAudioSource(
        AudioSource.uri(Uri.parse(streamUrl), headers: headers),
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
