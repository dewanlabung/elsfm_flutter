import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../data/models/player_state.dart' as player_models;
import '../../../data/models/track.dart';
import '../../../data/providers/api_client_provider.dart';
import '../../../data/providers/http_client_provider.dart';
import '../../../data/services/player_service.dart';
import '../../auth/models/auth_state.dart';
import '../../auth/providers/auth_notifier.dart';

// ExoPlayer repeat-mode constants (mirrors Player.REPEAT_MODE_* from Media3).
const int _repeatModeOff = 0;
const int _repeatModeOne = 1;
const int _repeatModeAll = 2;

class PlayerNotifier extends Notifier<player_models.PlayerState> {
  late PlayerService _playerService;

  @override
  player_models.PlayerState build() {
    final playerServiceAsync = ref.watch(playerServiceProvider);

    // Keep auth token in sync with auth state so API calls work after login.
    ref.listen<AuthStateData>(authNotifierProvider, (previous, next) {
      playerServiceAsync.whenData((service) async {
        if (next.state == AuthState.authenticated) {
          const storage = FlutterSecureStorage();
          final token = await storage.read(key: 'auth_token');
          service.setAuthToken(token);
        } else if (next.state == AuthState.unauthenticated) {
          service.setAuthToken(null);
        }
      });
    });

    return playerServiceAsync.when(
      data: (service) {
        _playerService = service;
        _initListeners(service);
        return const player_models.PlayerState(queue: []);
      },
      loading: () {
        _playerService = _stubService;
        return const player_models.PlayerState(queue: []);
      },
      error: (_, __) {
        _playerService = _stubService;
        return const player_models.PlayerState(queue: []);
      },
    );
  }

  void _initListeners(PlayerService service) {
    service.currentIndexStream.listen((index) {
      final prevIndex = state.currentIndex;
      state = state.copyWith(currentIndex: index);
      // Log play when track actually changes
      if (index != null &&
          prevIndex != null &&
          index != prevIndex &&
          state.tracks != null &&
          index < state.tracks!.length) {
        final trackId = state.tracks![index].id;
        ref.read(dioProvider.future).then((dio) {
          apiClientFromDio(dio).logTrackPlay(trackId);
        }).catchError((_) {});
      }
    });

    service.positionStream.listen((position) {
      state = state.copyWith(position: position);
    });

    service.durationStream.listen((duration) {
      state = state.copyWith(duration: duration ?? Duration.zero);
    });

    service.playerStateStream.listen((playerState) {
      state = state.copyWith(
        isPlaying: playerState.isPlaying,
        isLoading: playerState.isLoading,
      );
    });

    service.errorStream.listen((error) {
      state = state.copyWith(error: error);
    });
  }

  Future<void> setQueue(List<Track> tracks, {int startIndex = 0}) async {
    if (kDebugMode) {
      debugPrint('[PlayerNotifier] setQueue: ${tracks.length} tracks, startIndex: $startIndex');
    }
    final queueIds = tracks.map((t) => t.id).toList();
    state = state.copyWith(
        queue: queueIds, tracks: tracks, currentIndex: startIndex, error: null);
    try {
      await _playerService.setQueue(tracks);
      // playAtIndex starts playback at the correct position in the queue.
      await _playerService.playAtIndex(startIndex);
      if (kDebugMode) debugPrint('[PlayerNotifier] setQueue+play succeeded');
    } catch (e) {
      if (kDebugMode) debugPrint('[PlayerNotifier] setQueue error: $e');
      state = state.copyWith(error: 'Cannot play track: $e');
    }
  }

  /// Convenience method to play a single track immediately.
  Future<void> playTrack(Track track) => setQueue([track]);

  Future<void> play() async {
    state = state.copyWith(isLoading: true);
    try {
      await _playerService.play();
      state = state.copyWith(isPlaying: true, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> pause() async {
    await _playerService.pause();
    state = state.copyWith(isPlaying: false);
  }

  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(Duration position) async {
    await _playerService.seek(position);
  }

  Future<void> next() async {
    if (state.hasNext) {
      await _playerService.next();
    } else if (state.repeatMode == player_models.RepeatMode.all) {
      await _playerService.playAtIndex(0);
    }
  }

  Future<void> previous() async {
    if (state.hasPrevious) {
      await _playerService.previous();
    }
  }

  Future<void> toggleRepeat() async {
    final nextMode = switch (state.repeatMode) {
      player_models.RepeatMode.none => player_models.RepeatMode.one,
      player_models.RepeatMode.one  => player_models.RepeatMode.all,
      player_models.RepeatMode.all  => player_models.RepeatMode.none,
    };
    state = state.copyWith(repeatMode: nextMode);

    final loopModeInt = switch (nextMode) {
      player_models.RepeatMode.none => _repeatModeOff,
      player_models.RepeatMode.one  => _repeatModeOne,
      player_models.RepeatMode.all  => _repeatModeAll,
    };
    await _playerService.setLoopMode(loopModeInt);
  }

  void toggleShuffle() {
    final newShuffled = !state.isShuffled;
    state = state.copyWith(isShuffled: newShuffled);
    _playerService.setShuffle(newShuffled);
  }

  Future<void> setPlaybackRate(double rate) async {
    await _playerService.setPlaybackRate(rate);
    state = state.copyWith(playbackRate: rate);
  }
}

final playerServiceProvider = FutureProvider<PlayerService>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  final playerService = PlayerService();

  if (authState.state == AuthState.authenticated) {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      if (token != null) {
        playerService.setAuthToken(token);
      }
    } catch (_) {}
  }

  await playerService.init();
  ref.onDispose(() => playerService.dispose());
  return playerService;
});

// Single shared stub used for loading/error states — never plays audio.
final _stubService = PlayerService();

final playerProvider =
    NotifierProvider<PlayerNotifier, player_models.PlayerState>(
        PlayerNotifier.new);
