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
/// This service is a drop-in replacement for just_audio inside [PlayerService].
/// It exposes the same stream types so no upstream Riverpod providers change.
class NativePlayerService {
  static const _methodChannel =
      MethodChannel('com.elsfm.mobile/player');
  static const _eventChannel =
      EventChannel('com.elsfm.mobile/player_events');

  // ── Broadcast stream controllers ─────────────────────────────────────────
  final _isPlayingCtrl   = StreamController<bool>.broadcast();
  final _positionCtrl    = StreamController<Duration>.broadcast();
  final _durationCtrl    = StreamController<Duration?>.broadcast();
  final _currentIndexCtrl = StreamController<int?>.broadcast();
  final _stateCtrl       = StreamController<String>.broadcast();
  final _errorCtrl       = StreamController<String?>.broadcast();

  StreamSubscription<dynamic>? _eventSub;

  // ── Public streams (mirrors just_audio API) ───────────────────────────────
  Stream<bool>     get isPlayingStream    => _isPlayingCtrl.stream;
  Stream<Duration> get positionStream     => _positionCtrl.stream;
  Stream<Duration?> get durationStream   => _durationCtrl.stream;
  Stream<int?>     get currentIndexStream => _currentIndexCtrl.stream;
  Stream<String>   get playerStateStream  => _stateCtrl.stream;
  Stream<String?>  get errorStream        => _errorCtrl.stream;

  bool   _isPlaying    = false;
  int?   _currentIndex;
  Duration _position   = Duration.zero;
  Duration? _duration;

  bool     get isPlaying    => _isPlaying;
  int?     get currentIndex => _currentIndex;
  Duration get position     => _position;
  Duration? get duration    => _duration;

  // ── Init / dispose ────────────────────────────────────────────────────────
  void init() {
    _eventSub = _eventChannel.receiveBroadcastStream().listen(
      _onEvent,
      onError: (dynamic e) {
        _errorCtrl.add(e.toString());
      },
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

  /// Send the full queue to native and prepare ExoPlayer.
  /// Does NOT start playback — call [playAtIndex] or [play] afterwards.
  Future<void> setQueue(List<Track> tracks) async {
    final items = tracks
        .map((t) => {
              'id':     t.id,
              'url':    t.src,   // already resolved full HTTPS URL
              'title':  t.name,
              'artist': t.artists.isNotEmpty ? t.artists.first.name : '',
            })
        .toList();
    await _methodChannel.invokeMethod<void>('setQueue', {'items': items});
    if (kDebugMode) {
      debugPrint('[NativePlayerService] setQueue: ${tracks.length} tracks');
    }
  }

  Future<void> playAtIndex(int index) async {
    if (kDebugMode) debugPrint('[NativePlayerService] playAtIndex $index');
    await _methodChannel.invokeMethod<void>('playAtIndex', {'index': index});
  }

  Future<void> play() async {
    await _methodChannel.invokeMethod<void>('play');
  }

  Future<void> pause() async {
    await _methodChannel.invokeMethod<void>('pause');
  }

  Future<void> stop() async {
    await _methodChannel.invokeMethod<void>('stop');
  }

  Future<void> seekTo(Duration position) async {
    await _methodChannel.invokeMethod<void>(
        'seekTo', {'positionMs': position.inMilliseconds});
  }

  Future<void> skipNext() async {
    await _methodChannel.invokeMethod<void>('skipNext');
  }

  Future<void> skipPrevious() async {
    await _methodChannel.invokeMethod<void>('skipPrevious');
  }

  Future<void> setPlaybackSpeed(double speed) async {
    await _methodChannel.invokeMethod<void>('setPlaybackSpeed', {'speed': speed});
  }

  Future<void> setRepeatMode(int mode) async {
    await _methodChannel.invokeMethod<void>('setRepeatMode', {'mode': mode});
  }

  Future<void> setShuffleEnabled(bool enabled) async {
    await _methodChannel.invokeMethod<void>('setShuffleEnabled', {'enabled': enabled});
  }

  Future<void> dispose() async {
    await _eventSub?.cancel();
    _eventSub = null;
    await _methodChannel.invokeMethod<void>('release');
    await _isPlayingCtrl.close();
    await _positionCtrl.close();
    await _durationCtrl.close();
    await _currentIndexCtrl.close();
    await _stateCtrl.close();
    await _errorCtrl.close();
  }
}
