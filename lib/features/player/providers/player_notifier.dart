import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:just_audio/just_audio.dart';
import '../../../data/models/player_state.dart' as player_models;
import '../../../data/models/track.dart';
import '../../../data/services/player_service.dart';
import '../../../data/providers/api_client_provider.dart';

class PlayerNotifier extends StateNotifier<player_models.PlayerState> {
  final PlayerService playerService;
  Ref? _ref;

  PlayerNotifier(this.playerService, [this._ref]) : super(const player_models.PlayerState(queue: [])) {
    _initListeners();
  }

  void _initListeners() {
    playerService.currentIndexStream.listen((index) {
      state = state.copyWith(currentIndex: index);
    });

    playerService.positionStream.listen((position) {
      state = state.copyWith(position: position);
    });

    playerService.durationStream.listen((duration) {
      state = state.copyWith(duration: duration ?? Duration.zero);
    });

    playerService.playerStateStream.listen((playerState) {
      state = state.copyWith(
        isPlaying: playerState.isPlaying,
        isLoading: playerState.isLoading,
      );
    });

    playerService.errorStream.listen((error) {
      if (error != null) {
        state = state.copyWith(error: error);
      } else {
        state = state.copyWith(error: null);
      }
    });
  }

  Future<void> setQueue(List<Track> tracks, {int startIndex = 0}) async {
    final queueIds = tracks.map((t) => t.id).toList();
    state = state.copyWith(queue: queueIds, tracks: tracks, currentIndex: startIndex);
    await playerService.setQueue(tracks);
    await playerService.seek(Duration.zero);
    if (startIndex > 0) {
      await playerService.audioPlayer.seek(Duration.zero, index: startIndex);
    }
    await playerService.play();
    // Log play to backend after starting
    final trackId = tracks.isNotEmpty ? tracks[startIndex].id : null;
    if (trackId != null) {
      _ref?.read(apiClientProvider).logTrackPlay(trackId);
    }
  }

  /// Convenience method to play a single track immediately.
  Future<void> playTrack(Track track) => setQueue([track]);

  Future<void> play() async {
    state = state.copyWith(isLoading: true);
    try {
      await playerService.play();
      state = state.copyWith(isPlaying: true, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> pause() async {
    await playerService.pause();
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
    await playerService.seek(position);
  }

  Future<void> next() async {
    if (state.hasNext) {
      await playerService.next();
    } else if (state.repeatMode == player_models.RepeatMode.all) {
      await playerService.audioPlayer.seek(Duration.zero, index: 0);
      await play();
    }
  }

  Future<void> previous() async {
    if (state.hasPrevious) {
      await playerService.previous();
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
    await playerService.setLoopMode(loopMode);
  }

  void toggleShuffle() {
    final newShuffled = !state.isShuffled;
    state = state.copyWith(isShuffled: newShuffled);
    playerService.setShuffle(newShuffled);
  }

  Future<void> setPlaybackRate(double rate) async {
    await playerService.setPlaybackRate(rate);
    state = state.copyWith(playbackRate: rate);
  }

  @override
  Future<void> dispose() async {
    await playerService.dispose();
    super.dispose();
  }
}

final playerServiceProvider = FutureProvider<PlayerService>((ref) async {
  final playerService = PlayerService();

  // Set auth token BEFORE init so it is present when audio sources are loaded
  try {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'auth_token');
    if (token != null) {
      playerService.setAuthToken(token);
    }
  } catch (_) {}

  await playerService.init();
  ref.onDispose(() => playerService.dispose());
  return playerService;
});

// Single shared stub used for loading/error states — never plays audio,
// never leaks unauthenticated requests.
final _stubService = PlayerService();

final playerProvider = StateNotifierProvider<PlayerNotifier, player_models.PlayerState>((ref) {
  final playerServiceAsync = ref.watch(playerServiceProvider);
  return playerServiceAsync.when(
    data: (playerService) => PlayerNotifier(playerService, ref),
    loading: () => PlayerNotifier(_stubService),
    error: (_, __) => PlayerNotifier(_stubService),
  );
});
