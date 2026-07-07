import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/track.dart';

/// Dart wrapper around the native Android ExoPlayer / Media3 MethodChannel.
///
/// Channel layout:
///   MethodChannel  "com.elsfm.mobile/player"       Flutter → Native
///   EventChannel   "com.elsfm.mobile/player_events" Native → Flutter
///
/// Audio lives in [ElsfmPlaybackService] (MediaSessionService) so it
/// survives backgrounding, screen-off and lock-screen without extra work.
/// The system automatically shows a media notification with controls.
class NativePlayerService {
  static const _methodChannel =
      MethodChannel('com.elsfm.mobile/player');
  static const _eventChannel =
      EventChannel('com.elsfm.mobile/player_events');

  // ── Broadcast stream controllers ─────────────────────────────────────────
  final _isPlayingCtrl    = StreamController<bool>.broadcast();
  final _positionCtrl     = StreamController<Duration>.broadcast();
  final _durationCtrl     = StreamController<Duration?>.broadcast();
  final _currentIndexCtrl = StreamController<int?>.broadcast();
  final _stateCtrl        = StreamController<String>.broadcast();
  final _errorCtrl        = StreamController<String?>.broadcast();

  StreamSubscription<dynamic>? _eventSub;

  // ── Public streams ────────────────────────────────────────────────────────
  Stream<bool>     get isPlayingStream    => _isPlayingCtrl.stream;
  Stream<Duration> get positionStream     => _positionCtrl.stream;
  Stream<Duration?> get durationStream   => _durationCtrl.stream;
  Stream<int?>     get currentIndexStream => _currentIndexCtrl.stream;
  Stream<String>   get playerStateStream  => _stateCtrl.stream;
  Stream<String?>  get errorStream        => _errorCtrl.stream;

  // ── Cached values for synchronous reads ──────────────────────────────────
  bool      _isPlaying    = false;
  int?      _currentIndex;
  Duration  _position     = Duration.zero;
  Duration? _duration;

  bool      get isPlaying    => _isPlaying;
  int?      get currentIndex => _currentIndex;
  Duration  get position     => _position;
  Duration? get duration     => _duration;

  // ── Retry on NOT_CONNECTED ────────────────────────────────────────────────
  // The MediaController connects to ElsfmPlaybackService asynchronously.
  // If a command arrives before the connection is ready, retry once after 1 s.
  Future<T?> _invoke<T>(String method, [dynamic args]) async {
    try {
      return await _methodChannel.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      if (e.code == 'NOT_CONNECTED') {
        if (kDebugMode) debugPrint('[NativePlayerService] $method: not connected yet, retrying in 1s');
        await Future<void>.delayed(const Duration(seconds: 1));
        try {
          return await _methodChannel.invokeMethod<T>(method, args);
        } catch (e2) {
          if (kDebugMode) debugPrint('[NativePlayerService] $method retry failed: $e2');
          return null;
        }
      }
      if (kDebugMode) debugPrint('[NativePlayerService] $method error: ${e.message}');
      _errorCtrl.add(e.message);
      return null;
    }
  }

  // ── Init / dispose ────────────────────────────────────────────────────────
  void init() {
    _eventSub = _eventChannel.receiveBroadcastStream().listen(
      _onEvent,
      onError: (dynamic e) => _errorCtrl.add(e.toString()),
    );
  }

  void _onEvent(dynamic raw) {
    if (raw is! Map) return;
    final type  = raw['event'] as String?;
    final value = raw['value'];
    switch (type) {
      case 'isPlaying':
        _isPlaying = value as bool? ?? false;
        _isPlayingCtrl.add(_isPlaying);
      case 'position':
        final ms = _toLong(value);
        _position = Duration(milliseconds: ms);
        _positionCtrl.add(_position);
      case 'duration':
        final ms = _toLong(value);
        _duration = ms > 0 ? Duration(milliseconds: ms) : null;
        _durationCtrl.add(_duration);
      case 'currentIndex':
        _currentIndex = value as int?;
        _currentIndexCtrl.add(_currentIndex);
      case 'state':
        _stateCtrl.add(value as String? ?? 'idle');
      case 'error':
        final msg = value as String?;
        _errorCtrl.add(msg);
        if (kDebugMode) debugPrint('[NativePlayerService] error: $msg');
    }
  }

  static int _toLong(dynamic v) {
    if (v == null) return 0;
    if (v is int)    return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  // ── Playback control ──────────────────────────────────────────────────────

  Future<void> setQueue(List<Track> tracks) async {
    final items = tracks
        .map((t) => {
              'id':     t.id,
              'url':    t.src,
              'title':  t.name,
              'artist': t.artists.isNotEmpty ? t.artists.first.name : '',
            })
        .toList();
    await _invoke<void>('setQueue', {'items': items});
    if (kDebugMode) debugPrint('[NativePlayerService] setQueue: ${tracks.length} tracks');
  }

  Future<void> playAtIndex(int index) async {
    if (kDebugMode) debugPrint('[NativePlayerService] playAtIndex $index');
    await _invoke<void>('playAtIndex', {'index': index});
  }

  Future<void> play()  => _invoke<void>('play').then((_) {});
  Future<void> pause() => _invoke<void>('pause').then((_) {});
  Future<void> stop()  => _invoke<void>('stop').then((_) {});

  Future<void> seekTo(Duration position) =>
      _invoke<void>('seekTo', {'positionMs': position.inMilliseconds})
          .then((_) {});

  Future<void> skipNext()     => _invoke<void>('skipNext').then((_) {});
  Future<void> skipPrevious() => _invoke<void>('skipPrevious').then((_) {});

  Future<void> setPlaybackSpeed(double speed) =>
      _invoke<void>('setPlaybackSpeed', {'speed': speed}).then((_) {});

  Future<void> setRepeatMode(int mode) =>
      _invoke<void>('setRepeatMode', {'mode': mode}).then((_) {});

  Future<void> setShuffleEnabled(bool enabled) =>
      _invoke<void>('setShuffleEnabled', {'enabled': enabled}).then((_) {});

  // ── Dispose ───────────────────────────────────────────────────────────────
  Future<void> dispose() async {
    await _eventSub?.cancel();
    _eventSub = null;
    await _invoke<void>('release');
    await _isPlayingCtrl.close();
    await _positionCtrl.close();
    await _durationCtrl.close();
    await _currentIndexCtrl.close();
    await _stateCtrl.close();
    await _errorCtrl.close();
  }
}
