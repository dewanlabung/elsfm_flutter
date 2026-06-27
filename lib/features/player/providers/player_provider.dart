import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/player_service.dart';
import 'package:elsfm/data/models/track.dart';

/// Player service provider (singleton)
final playerServiceProvider = Provider<PlayerService>((ref) {
  return PlayerService();
});

/// Current track provider
final currentTrackProvider = StateProvider<Track?>((ref) {
  final service = ref.watch(playerServiceProvider);
  return service.currentTrack;
});

/// Current queue provider
final queueProvider = StateProvider<List<Track>>((ref) {
  final service = ref.watch(playerServiceProvider);
  return service.queue;
});

/// Playing state provider
final isPlayingProvider = StateProvider<bool>((ref) {
  final service = ref.watch(playerServiceProvider);
  return service.isPlaying;
});

/// Current position provider
final positionProvider = StateProvider<Duration>((ref) {
  final service = ref.watch(playerServiceProvider);
  return service.position;
});

/// Duration provider
final durationProvider = StateProvider<Duration>((ref) {
  final service = ref.watch(playerServiceProvider);
  return service.duration;
});

/// Playback speed provider
final playbackSpeedProvider = StateProvider<double>((ref) {
  final service = ref.watch(playerServiceProvider);
  return service.playbackSpeed;
});

/// Shuffle state provider
final isShuffledProvider = StateProvider<bool>((ref) {
  final service = ref.watch(playerServiceProvider);
  return service.isShuffled;
});

/// Repeat mode provider
final repeatModeProvider = StateProvider<RepeatMode>((ref) {
  final service = ref.watch(playerServiceProvider);
  return service.repeatMode;
});

/// Player notifier for state updates
class PlayerNotifier extends StateNotifier<PlayerState> {
  final Ref ref;

  PlayerNotifier(this.ref) : super(const PlayerState());

  Future<void> loadTrack(Track track) async {
    final service = ref.read(playerServiceProvider);
    try {
      await service.loadTrack(track);
      state = state.copyWith(currentTrack: track, isPlaying: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadQueue(List<Track> tracks, {int startIndex = 0}) async {
    final service = ref.read(playerServiceProvider);
    try {
      await service.loadQueue(tracks, startIndex: startIndex);
      state = state.copyWith(queue: tracks, isPlaying: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> togglePlayPause() async {
    final service = ref.read(playerServiceProvider);
    try {
      await service.togglePlayPause();
      state = state.copyWith(isPlaying: service.isPlaying);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> next() async {
    final service = ref.read(playerServiceProvider);
    try {
      await service.next();
      state = state.copyWith(currentTrack: service.currentTrack);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> previous() async {
    final service = ref.read(playerServiceProvider);
    try {
      await service.previous();
      state = state.copyWith(currentTrack: service.currentTrack);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> seek(Duration position) async {
    final service = ref.read(playerServiceProvider);
    try {
      await service.seek(position);
      state = state.copyWith(position: position);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleShuffle() async {
    final service = ref.read(playerServiceProvider);
    try {
      await service.toggleShuffle();
      state = state.copyWith(isShuffled: service.isShuffled);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> cycleRepeatMode() async {
    final service = ref.read(playerServiceProvider);
    try {
      await service.cycleRepeatMode();
      state = state.copyWith(repeatMode: service.repeatMode);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Player state
class PlayerState {
  final Track? currentTrack;
  final List<Track> queue;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final double playbackSpeed;
  final bool isShuffled;
  final RepeatMode repeatMode;
  final String? error;

  const PlayerState({
    this.currentTrack,
    this.queue = const [],
    this.isPlaying = false,
    this.position = const Duration(),
    this.duration = const Duration(),
    this.playbackSpeed = 1.0,
    this.isShuffled = false,
    this.repeatMode = RepeatMode.off,
    this.error,
  });

  PlayerState copyWith({
    Track? currentTrack,
    List<Track>? queue,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    double? playbackSpeed,
    bool? isShuffled,
    RepeatMode? repeatMode,
    String? error,
  }) {
    return PlayerState(
      currentTrack: currentTrack ?? this.currentTrack,
      queue: queue ?? this.queue,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      isShuffled: isShuffled ?? this.isShuffled,
      repeatMode: repeatMode ?? this.repeatMode,
      error: error ?? this.error,
    );
  }
}

/// Main player state provider
final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerState>(
  (ref) => PlayerNotifier(ref),
);

enum RepeatMode { off, one, all }
