import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/player_notifier.dart';

/// Mini player widget for bottom of screen
class MiniPlayer extends ConsumerWidget {
  final VoidCallback? onExpanded;

  const MiniPlayer({super.key, this.onExpanded});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final currentTrack = playerState.currentTrack;
    // Controls are disabled until the real authenticated PlayerService is ready
    final playerReady = ref.watch(playerServiceProvider).hasValue;

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
            // Error banner
            if (playerState.error != null)
              Container(
                width: double.infinity,
                color: Colors.red.withOpacity(0.8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Text(
                  'Playback error — ${playerState.error}',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            // Player info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Album art
                  Builder(
                    builder: (_) {
                      final raw = currentTrack.image ?? '';
                      final url = raw.startsWith('http')
                          ? raw
                          : raw.isNotEmpty
                              ? 'https://www.elsfm.com/$raw'
                              : '';
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: url.isNotEmpty
                            ? Image.network(
                                url,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 40,
                                  height: 40,
                                  color: Colors.grey[800],
                                  child: const Icon(Icons.music_note, size: 20),
                                ),
                              )
                            : Container(
                                width: 40,
                                height: 40,
                                color: Colors.grey[800],
                                child: const Icon(Icons.music_note, size: 20),
                              ),
                      );
                    },
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
                  // Play/pause — disabled until authenticated PlayerService ready
                  IconButton(
                    icon: Icon(
                      playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 20,
                    ),
                    onPressed: playerReady
                        ? () => ref.read(playerProvider.notifier).togglePlayPause()
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next, size: 20),
                    onPressed: playerReady
                        ? () => ref.read(playerProvider.notifier).next()
                        : null,
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
