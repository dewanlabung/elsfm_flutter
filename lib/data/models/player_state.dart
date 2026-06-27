import 'track.dart';

enum RepeatMode { none, one, all }

class PlayerState {
  final List<int> queue; // Queue of track IDs
  final List<Track> tracks; // Full track objects for the queue
  final int? currentIndex;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool isLoading;
  final RepeatMode repeatMode;
  final bool isShuffled;
  final double playbackRate;
  final String? error;

  const PlayerState({
    required this.queue,
    this.tracks = const [],
    this.currentIndex,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isPlaying = false,
    this.isLoading = false,
    this.repeatMode = RepeatMode.none,
    this.isShuffled = false,
    this.playbackRate = 1.0,
    this.error,
  });

  Track? get currentTrack =>
      currentIndex != null && currentIndex! >= 0 && currentIndex! < tracks.length
          ? tracks[currentIndex!]
          : null;

  bool get hasNext => currentIndex != null && currentIndex! < queue.length - 1;
  bool get hasPrevious => currentIndex != null && currentIndex! > 0;

  PlayerState copyWith({
    List<int>? queue,
    List<Track>? tracks,
    int? currentIndex,
    Duration? position,
    Duration? duration,
    bool? isPlaying,
    bool? isLoading,
    RepeatMode? repeatMode,
    bool? isShuffled,
    double? playbackRate,
    String? error,
  }) {
    return PlayerState(
      queue: queue ?? this.queue,
      tracks: tracks ?? this.tracks,
      currentIndex: currentIndex ?? this.currentIndex,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      repeatMode: repeatMode ?? this.repeatMode,
      isShuffled: isShuffled ?? this.isShuffled,
      playbackRate: playbackRate ?? this.playbackRate,
      error: error ?? this.error,
    );
  }
}
