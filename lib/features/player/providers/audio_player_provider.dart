import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../services/audio_streaming_service.dart';
import '../../../data/providers/http_client_provider.dart';

/// Provider for audio streaming service.
///
/// Uses the authenticated [dioProvider] so the service inherits the
/// Authorization header that is set after login. Disposes the service
/// (and its underlying AudioPlayer) when the provider is removed.
final audioStreamingServiceProvider = Provider<AudioStreamingService>((ref) {
  final dio = ref.watch(dioProvider).requireValue;
  final service = AudioStreamingService(dio: dio);
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for audio player position stream
final audioPlayerPositionProvider = StreamProvider<Duration>((ref) {
  final audioService = ref.watch(audioStreamingServiceProvider);
  return audioService.getPositionStream();
});

/// Provider for audio player state stream
final audioPlayerStateProvider = StreamProvider<PlayerState>((ref) {
  final audioService = ref.watch(audioStreamingServiceProvider);
  return audioService.getPlayerStateStream();
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
