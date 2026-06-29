import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../services/audio_streaming_service.dart';
import '../../../data/providers/http_client_provider.dart';

/// Provider for audio streaming service.
///
/// Uses [dioProvider] (async) so the service inherits the Authorization header
/// set after login. Returns null while Dio is still initialising — callers
/// should guard with [AsyncValue.when] rather than relying on a synchronous
/// throw from [requireValue].
final audioStreamingServiceProvider =
    FutureProvider<AudioStreamingService>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  final service = AudioStreamingService(dio: dio);
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for audio player position stream.
final audioPlayerPositionProvider = StreamProvider<Duration>((ref) {
  final serviceAsync = ref.watch(audioStreamingServiceProvider);
  return serviceAsync.when(
    data: (service) => service.getPositionStream(),
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

/// Provider for audio player state stream.
final audioPlayerStateProvider = StreamProvider<PlayerState>((ref) {
  final serviceAsync = ref.watch(audioStreamingServiceProvider);
  return serviceAsync.when(
    data: (service) => service.getPlayerStateStream(),
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

/// Provider for current playback position (not a stream).
final currentPlaybackPositionProvider = Provider<Duration>((ref) {
  return ref.watch(audioStreamingServiceProvider).when(
    data: (service) => service.currentPosition,
    loading: () => Duration.zero,
    error: (_, __) => Duration.zero,
  );
});

/// Provider for track duration.
final trackDurationProvider = Provider<Duration?>((ref) {
  return ref.watch(audioStreamingServiceProvider).when(
    data: (service) => service.getDuration(),
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider for playback state.
final isPlayingProvider = Provider<bool>((ref) {
  return ref.watch(audioStreamingServiceProvider).when(
    data: (service) => service.isPlaying,
    loading: () => false,
    error: (_, __) => false,
  );
});
