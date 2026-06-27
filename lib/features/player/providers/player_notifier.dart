import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../data/models/player_state.dart' as player_models;
import '../../../data/models/track.dart';
import '../../../data/services/player_service.dart';

class PlayerNotifier extends StateNotifier<player_models.PlayerState> {
  final PlayerService playerService;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  PlayerNotifier(this.playerService) : super(const player_models.PlayerState(queue: [])) {
    _initListeners();
  }

  void _initListeners() {
    _subscriptions.add(
      playerService.currentIndexStream.listen((index) {
        state = state.copyWith(currentIndex: index);
      }),
    );

    _subscriptions.add(
      playerService.positionStream.listen((position) {
        state = state.copyWith(position: position);
      }),
    );

    _subscriptions.add(
      playerService.durationStream.listen((duration) {
        state = state.copyWith(duration: duration ?? Duration.zero);
      }),
    );

    _subscriptions.add(
      playerService.playerStateStream.listen((playerState) {
        state = state.copyWith(
          isPlaying: playerState.isPlaying,
          isLoading: playerState.isLoading,
        );
      }),
    );

    _subscriptions.add(
      playerService.errorStream.listen((error) {
        if (error != null) {
          state = state.copyWith(error: error);
        } else {
          state = state.copyWith(error: null);
        }
      }),
    );
  }

  Future<void> setQueue(List<Track> tracks, {int startIndex = 0}) async {
    final queueIds = tracks.map((t) => t.id).toList();
    state = state.copyWith(queue: queueIds, currentIndex: startIndex);
    await playerService.setQueue(tracks);
    await playerService.seek(Duration.zero);
    if (startIndex > 0) {
      await playerService.audioPlayer.seek(Duration.zero, index: startIndex);
    }
  }

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
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    playerService.dispose();
    super.dispose();
  }
}

final playerServiceProvider = FutureProvider<PlayerService>((ref) async {
  final playerService = PlayerService();
  await playerService.init();
  ref.onDispose(() => playerService.dispose());
  return playerService;
});

final playerProvider = StateNotifierProvider<PlayerNotifier, player_models.PlayerState>((ref) {
  final playerServiceAsync = ref.watch(playerServiceProvider);

  return playerServiceAsync.when(
    data: (playerService) => PlayerNotifier(playerService),
    loading: () => PlayerNotifier(PlayerService()..init()),
    error: (err, st) => PlayerNotifier(PlayerService()..init()),
  );
});
