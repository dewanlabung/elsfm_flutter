import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/player_provider.dart';

/// Now Playing screen (full player)
class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final currentTrack = playerState.currentTrack;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.expand_more),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              // Add to favorites
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show menu
            },
          ),
        ],
      ),
      body: currentTrack == null
          ? const Center(child: Text('No track loaded'))
          : Column(
              children: [
                // Album art
                Expanded(
                  flex: 2,
                  child: Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.music_note, size: 100),
                  ),
                ),
                // Track info
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          currentTrack.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentTrack.artists.map((a) => a.name).join(', '),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                // Progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                        ),
                        child: Slider(
                          value: playerState.position.inSeconds.toDouble(),
                          max: playerState.duration.inSeconds.toDouble(),
                          onChanged: (value) {
                            ref
                                .read(playerProvider.notifier)
                                .seek(Duration(seconds: value.toInt()));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(playerState.position),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              _formatDuration(playerState.duration),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Player controls
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(
                          playerState.isShuffled
                              ? Icons.shuffle_on
                              : Icons.shuffle,
                        ),
                        onPressed: () {
                          ref.read(playerProvider.notifier).toggleShuffle();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        onPressed: () {
                          ref.read(playerProvider.notifier).previous();
                        },
                      ),
                      FloatingActionButton(
                        onPressed: () {
                          ref
                              .read(playerProvider.notifier)
                              .togglePlayPause();
                        },
                        child: Icon(
                          playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        onPressed: () {
                          ref.read(playerProvider.notifier).next();
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          _getRepeatIcon(playerState.repeatMode),
                        ),
                        onPressed: () {
                          ref.read(playerProvider.notifier).cycleRepeatMode();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  IconData _getRepeatIcon(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.off:
        return Icons.repeat;
      case RepeatMode.one:
        return Icons.repeat_one;
      case RepeatMode.all:
        return Icons.repeat_on;
    }
  }
}
