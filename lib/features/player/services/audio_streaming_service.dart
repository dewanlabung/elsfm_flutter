import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';
import 'package:elsfm/data/models/track.dart';

/// Audio streaming service that handles stream URL fetching and playback
class AudioStreamingService {
  final Dio dio;
  final AudioPlayer audioPlayer = AudioPlayer();

  AudioStreamingService({required this.dio});

  /// Get stream URL for a track at specific quality
  Future<String> getStreamUrl({
    required int trackId,
    required String quality,
  }) async {
    try {
      final response = await dio.get(
        '/api/v1/tracks/$trackId/stream',
        queryParameters: {
          'quality': quality,
        },
      );

      if (response.data?['url'] == null) {
        throw AudioStreamException('No stream URL returned from API');
      }

      return response.data['url'] as String;
    } on DioException catch (e) {
      throw AudioStreamException('Failed to get stream URL: $e');
    }
  }

  /// Load a track for playback
  Future<void> loadTrack({
    required Track track,
    required String quality,
  }) async {
    try {
      final streamUrl = await getStreamUrl(
        trackId: track.id,
        quality: quality,
      );

      // Validate the stream URL before passing it to the audio player.
      // Only HTTPS URLs from the trusted elsfm.com host are allowed.
      final uri = Uri.tryParse(streamUrl);
      if (uri == null || uri.scheme != 'https' || uri.host != 'www.elsfm.com') {
        throw AudioStreamException('Invalid or untrusted stream URL: $streamUrl');
      }

      await audioPlayer.setUrl(streamUrl);
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
