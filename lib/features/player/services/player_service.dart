import 'package:elsfm/data/models/track.dart';

/// Audio player service managing playback state
class PlayerService {
  // Player state
  Track? _currentTrack;
  List<Track> _queue = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _playbackSpeed = 1.0;
  bool _isShuffled = false;
  RepeatMode _repeatMode = RepeatMode.off;

  // Getters
  Track? get currentTrack => _currentTrack;
  List<Track> get queue => _queue;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  double get playbackSpeed => _playbackSpeed;
  bool get isShuffled => _isShuffled;
  RepeatMode get repeatMode => _repeatMode;

  /// Load and play a track
  Future<void> loadTrack(Track track) async {
    try {
      _currentTrack = track;
      _isPlaying = true;
      _position = Duration.zero;
      _duration = Duration(seconds: track.duration.inSeconds);
    } catch (e) {
      throw PlayerException('Failed to load track: $e');
    }
  }

  /// Load a queue and start playing
  Future<void> loadQueue(List<Track> tracks, {int startIndex = 0}) async {
    try {
      _queue = tracks;
      _currentIndex = startIndex.clamp(0, tracks.length - 1);
      if (tracks.isNotEmpty) {
        await loadTrack(tracks[_currentIndex]);
      }
    } catch (e) {
      throw PlayerException('Failed to load queue: $e');
    }
  }

  /// Play/pause
  Future<void> play() async {
    try {
      _isPlaying = true;
    } catch (e) {
      throw PlayerException('Failed to play: $e');
    }
  }

  Future<void> pause() async {
    try {
      _isPlaying = false;
    } catch (e) {
      throw PlayerException('Failed to pause: $e');
    }
  }

  Future<void> togglePlayPause() async {
    try {
      _isPlaying ? await pause() : await play();
    } catch (e) {
      throw PlayerException('Failed to toggle playback: $e');
    }
  }

  /// Navigation
  Future<void> next() async {
    try {
      if (_queue.isNotEmpty) {
        _currentIndex = (_currentIndex + 1) % _queue.length;
        await loadTrack(_queue[_currentIndex]);
      }
    } catch (e) {
      throw PlayerException('Failed to play next: $e');
    }
  }

  Future<void> previous() async {
    try {
      if (_queue.isNotEmpty) {
        _currentIndex = (_currentIndex - 1) % _queue.length;
        if (_currentIndex < 0) _currentIndex = _queue.length - 1;
        await loadTrack(_queue[_currentIndex]);
      }
    } catch (e) {
      throw PlayerException('Failed to play previous: $e');
    }
  }

  /// Seek
  Future<void> seek(Duration position) async {
    try {
      _position = position.clamp(Duration.zero, _duration);
    } catch (e) {
      throw PlayerException('Failed to seek: $e');
    }
  }

  /// Playback speed
  Future<void> setPlaybackSpeed(double speed) async {
    try {
      _playbackSpeed = speed.clamp(0.5, 2.0);
    } catch (e) {
      throw PlayerException('Failed to set playback speed: $e');
    }
  }

  /// Shuffle
  Future<void> toggleShuffle() async {
    try {
      _isShuffled = !_isShuffled;
      if (_isShuffled) {
        _queue.shuffle();
      }
    } catch (e) {
      throw PlayerException('Failed to toggle shuffle: $e');
    }
  }

  /// Repeat
  Future<void> cycleRepeatMode() async {
    try {
      _repeatMode = RepeatMode.values[
        (RepeatMode.values.indexOf(_repeatMode) + 1) % RepeatMode.values.length
      ];
    } catch (e) {
      throw PlayerException('Failed to cycle repeat: $e');
    }
  }

  /// Update position (called from UI during playback)
  void updatePosition(Duration newPosition) {
    _position = newPosition;
  }

  /// Get queue for display
  List<Track> getQueueFromCurrentTrack() {
    if (_currentIndex >= 0 && _currentIndex < _queue.length) {
      return _queue.sublist(_currentIndex);
    }
    return [];
  }
}

enum RepeatMode { off, one, all }

class PlayerException implements Exception {
  final String message;
  PlayerException(this.message);

  @override
  String toString() => 'PlayerException: $message';
}
