import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/player_provider.dart';

/// Mini player widget for bottom of screen
class MiniPlayer extends ConsumerWidget {
  final VoidCallback? onExpanded;

  const MiniPlayer({super.key, this.onExpanded});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final currentTrack = playerState.currentTrack;

    if (currentTrack == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onExpanded,
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: playerState.duration.inSeconds > 0
                  ? playerState.position.inSeconds /
                      playerState.duration.inSeconds
                  : 0,
              minHeight: 2,
            ),
            // Player info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Album art
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Icon(Icons.music_note, size: 20),
                  ),
                  const SizedBox(width: 12),
                  // Track info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentTrack.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          currentTrack.artists.map((a) => a.name).join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  // Play/pause button
                  IconButton(
                    icon: Icon(
                      playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 20,
                    ),
                    onPressed: () {
                      ref.read(playerProvider.notifier).togglePlayPause();
                    },
                  ),
                  // Next button
                  IconButton(
                    icon: const Icon(Icons.skip_next, size: 20),
                    onPressed: () {
                      ref.read(playerProvider.notifier).next();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
