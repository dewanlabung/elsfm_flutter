import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:just_audio/just_audio.dart';
import '../../../data/models/player_state.dart' as player_models;
import '../../../data/models/track.dart';
import '../../../data/services/player_service.dart';
import '../../../data/providers/http_client_provider.dart';
import '../../../data/providers/api_client_provider.dart';
import '../../auth/providers/auth_notifier.dart';
import '../../auth/models/auth_state.dart';

class PlayerNotifier extends Notifier<player_models.PlayerState> {
  late PlayerService _playerService;

  @override
  player_models.PlayerState build() {
    final playerServiceAsync = ref.watch(playerServiceProvider);

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
      state = state.copyWith(currentIndex: index);
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
    final queueIds = tracks.map((t) => t.id).toList();
    state = state.copyWith(queue: queueIds, tracks: tracks, currentIndex: startIndex);
    await _playerService.setQueue(tracks);
    await _playerService.seek(Duration.zero);
    if (startIndex > 0) {
      await _playerService.audioPlayer.seek(Duration.zero, index: startIndex);
    }
    await _playerService.play();

    final trackId = tracks.isNotEmpty ? tracks[startIndex].id : null;
    if (trackId != null) {
      // Fire-and-forget: log the play using the async dioProvider.
      ref.read(dioProvider.future).then((dio) {
        apiClientFromDio(dio).logTrackPlay(trackId);
      }).catchError((_) {});
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
      await _playerService.audioPlayer.seek(Duration.zero, index: 0);
      await play();
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
      player_models.RepeatMode.one => player_models.RepeatMode.all,
      player_models.RepeatMode.all => player_models.RepeatMode.none,
    };
    state = state.copyWith(repeatMode: nextMode);

    final loopMode = switch (nextMode) {
      player_models.RepeatMode.none => LoopMode.off,
      player_models.RepeatMode.one => LoopMode.one,
      player_models.RepeatMode.all => LoopMode.all,
    };
    await _playerService.setLoopMode(loopMode);
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
  // Watch auth notifier state to trigger re-initialization on login/logout.
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

// Single shared stub used for loading/error states — never plays audio,
// never leaks unauthenticated requests.
final _stubService = PlayerService();

final playerProvider =
    NotifierProvider<PlayerNotifier, player_models.PlayerState>(
  PlayerNotifier.new,
);
