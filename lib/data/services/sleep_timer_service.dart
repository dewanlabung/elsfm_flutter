import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sleep timer service that manages auto-pause scheduling.
class SleepTimerService {
  Duration? _timerDuration;
  DateTime? _startTime;
  DateTime? _targetTime;
  Function()? _onTimerComplete;
  bool _isRunning = false;

  /// Check if a timer is currently running.
  bool get isRunning => _isRunning;

  /// Get remaining time in seconds, or null if no timer is running.
  Duration? get remainingTime {
    if (!_isRunning || _targetTime == null) return null;
    final remaining = _targetTime!.difference(DateTime.now());
    if (remaining.isNegative) return Duration.zero;
    return remaining;
  }

  /// Get total duration of the sleep timer.
  Duration? get timerDuration => _timerDuration;

  /// Start a sleep timer that will call [onComplete] when it expires.
  ///
  /// [duration] - How long until the timer fires (e.g., 5 minutes)
  /// [onComplete] - Callback invoked when timer expires (typically: pause playback)
  void startTimer({
    required Duration duration,
    required Function() onComplete,
  }) {
    _timerDuration = duration;
    _startTime = DateTime.now();
    _targetTime = DateTime.now().add(duration);
    _onTimerComplete = onComplete;
    _isRunning = true;

    // Simulate timer tick every second
    _scheduleNextTick();
  }

  /// Cancel the active sleep timer.
  void cancelTimer() {
    _isRunning = false;
    _timerDuration = null;
    _startTime = null;
    _targetTime = null;
    _onTimerComplete = null;
  }

  /// Extend timer by [duration].
  void extendTimer(Duration duration) {
    if (!_isRunning) return;
    _targetTime = _targetTime?.add(duration);
    if (_timerDuration != null) {
      _timerDuration = _timerDuration! + duration;
    }
  }

  void _scheduleNextTick() {
    if (!_isRunning) return;

    Future.delayed(Duration(seconds: 1), () {
      if (!_isRunning) return;

      final remaining = remainingTime;
      if (remaining != null && remaining.inSeconds > 0) {
        _scheduleNextTick();
      } else {
        // Timer expired
        _isRunning = false;
        _onTimerComplete?.call();
      }
    });
  }
}

/// Riverpod provider for the sleep timer service.
final sleepTimerServiceProvider = Provider((ref) {
  return SleepTimerService();
});

/// Riverpod provider for sleep timer remaining time (updates every second).
final sleepTimerRemainingProvider = StreamProvider((ref) async* {
  final service = ref.watch(sleepTimerServiceProvider);

  if (!service.isRunning) {
    yield null;
  } else {
    while (service.isRunning) {
      yield service.remainingTime;
      await Future.delayed(Duration(seconds: 1));
    }
    yield null;
  }
});

/// Riverpod provider for sleep timer running state.
final sleepTimerRunningProvider = StateNotifierProvider<
    SleepTimerNotifier,
    bool>((ref) {
  final service = ref.watch(sleepTimerServiceProvider);
  return SleepTimerNotifier(service);
});

class SleepTimerNotifier extends StateNotifier<bool> {
  final SleepTimerService _service;

  SleepTimerNotifier(this._service) : super(false);

  void startTimer(Duration duration, Function() onComplete) {
    _service.startTimer(
      duration: duration,
      onComplete: () {
        onComplete();
        state = false;
      },
    );
    state = true;
  }

  void cancelTimer() {
    _service.cancelTimer();
    state = false;
  }

  void extendTimer(Duration duration) {
    _service.extendTimer(duration);
  }

  Duration? get remainingTime => _service.remainingTime;
}
