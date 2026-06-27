import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../services/audio_streaming_service.dart';

/// Provider for audio streaming service (singleton)
final audioStreamingServiceProvider = Provider<AudioStreamingService>((ref) {
  // Get Dio instance from dependency injection
  // In a real app, this would come from a proper DI container
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://www.elsfm.com',
      headers: {
        'Authorization': 'Bearer YOUR_TOKEN_HERE', // Token would come from auth provider
      },
    ),
  );

  return AudioStreamingService(dio: dio);
});

/// Provider for audio player position stream
final audioPlayerPositionProvider = StreamProvider<Duration>((ref) {
  final audioService = ref.watch(audioStreamingServiceProvider);
  return audioService.getPositionStream();
});

/// Provider for audio player state stream
final audioPlayerStateProvider = StreamProvider<Duration>((ref) {
  final audioService = ref.watch(audioStreamingServiceProvider);
  return audioService.getPositionStream();
});

/// Provider for current playback position (not a stream)
final currentPlaybackPositionProvider = Provider<Duration>((ref) {
  final audioService = ref.watch(audioStreamingServiceProvider);
  return audioService.currentPosition;
});

/// Provider for track duration
final trackDurationProvider = Provider<Duration?>((ref) {
  final audioService = ref.watch(audioStreamingServiceProvider);
  return audioService.getDuration();
});

/// Provider for playback state
final isPlayingProvider = Provider<bool>((ref) {
  final audioService = ref.watch(audioStreamingServiceProvider);
  return audioService.isPlaying;
});
