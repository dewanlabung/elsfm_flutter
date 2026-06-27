import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/player_state.dart' as ps;
import '../providers/player_notifier.dart';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);

    if (playerState.queue.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Now Playing')),
        body: const Center(child: Text('No track playing')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_note,
                    size: 120,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Now Playing',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (playerState.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  if (playerState.error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        playerState.error!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.red),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Progress bar and controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      _formatDuration(playerState.position),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Expanded(
                      child: Slider(
                        value: playerState.position.inMilliseconds.toDouble(),
                        max: (playerState.duration.inMilliseconds.toDouble()) + 1,
                        onChanged: (value) {
                          ref.read(playerProvider.notifier).seek(
                            Duration(milliseconds: value.toInt()),
                          );
                        },
                      ),
                    ),
                    Text(
                      _formatDuration(playerState.duration),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () {
                        ref.read(playerProvider.notifier).toggleShuffle();
                      },
                      icon: Icon(
                        Icons.shuffle,
                        color: playerState.isShuffled
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                    ),
                    IconButton(
                      onPressed: playerState.hasPrevious
                          ? () {
                              ref.read(playerProvider.notifier).previous();
                            }
                          : null,
                      icon: const Icon(Icons.skip_previous, size: 32),
                    ),
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: IconButton(
                        iconSize: 32,
                        onPressed: () {
                          ref.read(playerProvider.notifier).togglePlayPause();
                        },
                        icon: Icon(
                          playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: playerState.hasNext
                          ? () {
                              ref.read(playerProvider.notifier).next();
                            }
                          : null,
                      icon: const Icon(Icons.skip_next, size: 32),
                    ),
                    IconButton(
                      onPressed: () {
                        ref.read(playerProvider.notifier).toggleRepeat();
                      },
                      icon: Icon(
                        Icons.repeat,
                        color: playerState.repeatMode == ps.RepeatMode.none
                            ? Colors.grey
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
