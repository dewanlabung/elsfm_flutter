enum RepeatMode { none, one, all }

class PlayerState {
  final List<int> queue; // Queue of track IDs
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

  bool get hasNext => currentIndex != null && currentIndex! < queue.length - 1;
  bool get hasPrevious => currentIndex != null && currentIndex! > 0;

  PlayerState copyWith({
    List<int>? queue,
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
