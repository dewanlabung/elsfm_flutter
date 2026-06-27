import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/player_notifier.dart';
import 'package:elsfm/data/models/player_state.dart';

/// Playback controls widget (shuffle, previous, play/pause, next, repeat)
class PlaybackControls extends ConsumerWidget {
  const PlaybackControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Shuffle toggle
          IconButton(
            icon: Icon(
              playerState.isShuffled
                  ? Icons.shuffle_on
                  : Icons.shuffle,
              color: playerState.isShuffled
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: () {
              ref.read(playerProvider.notifier).toggleShuffle();
            },
          ),
          // Previous button
          IconButton(
            icon: const Icon(Icons.skip_previous),
            iconSize: 32,
            onPressed: () {
              ref.read(playerProvider.notifier).previous();
            },
          ),
          // Play/Pause FAB
          FloatingActionButton(
            onPressed: () {
              ref.read(playerProvider.notifier).togglePlayPause();
            },
            child: Icon(
              playerState.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow,
            ),
          ),
          // Next button
          IconButton(
            icon: const Icon(Icons.skip_next),
            iconSize: 32,
            onPressed: () {
              ref.read(playerProvider.notifier).next();
            },
          ),
          // Repeat cycle
          IconButton(
            icon: Icon(
              _getRepeatIcon(playerState.repeatMode),
              color: playerState.repeatMode != RepeatMode.none
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: () {
              ref.read(playerProvider.notifier).toggleRepeat();
            },
          ),
        ],
      ),
    );
  }

  IconData _getRepeatIcon(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.none:
        return Icons.repeat;
      case RepeatMode.one:
        return Icons.repeat_one;
      case RepeatMode.all:
        return Icons.repeat_on;
    }
  }
}
