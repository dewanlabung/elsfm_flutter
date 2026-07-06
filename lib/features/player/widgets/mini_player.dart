import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/app_config.dart';
import '../providers/player_notifier.dart';
import '../../analytics/providers/analytics_notifier.dart';

class MiniPlayer extends ConsumerWidget {
  final VoidCallback? onExpanded;

  const MiniPlayer({super.key, this.onExpanded});

  String? _resolveImage(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    return '${AppConfig.webBaseUrl}/$raw';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final currentTrack = playerState.currentTrack;
    final playerReady = ref.watch(playerServiceProvider).hasValue;

    if (currentTrack == null) return const SizedBox.shrink();

    final imageUrl = _resolveImage(currentTrack.image);
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onExpanded,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          border: Border(
            top: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: playerState.duration.inSeconds > 0
                  ? (playerState.position.inSeconds /
                          playerState.duration.inSeconds)
                      .clamp(0.0, 1.0)
                  : 0.0,
              minHeight: 2,
              backgroundColor: colorScheme.outlineVariant,
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Album art
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _artBox(),
                          )
                        : _artBox(),
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
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        Text(
                          currentTrack.artists.map((a) => a.name).join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ),
                  // Play/pause
                  IconButton(
                    icon: Icon(
                      playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                    onPressed: playerReady
                        ? () {
                            ref
                                .read(playerProvider.notifier)
                                .togglePlayPause();
                            // Track play/pause event
                            ref.read(analyticsProvider.notifier).trackPlayerEvent(
                              action: playerState.isPlaying
                                  ? 'pause'
                                  : 'play',
                              trackId: currentTrack.id.toString(),
                              trackName: currentTrack.name,
                              artistName: currentTrack.artists
                                  .map((a) => a.name)
                                  .join(', '),
                            );
                          }
                        : null,
                  ),
                  // Next
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: playerReady
                        ? () {
                            ref.read(playerProvider.notifier).next();
                            // Track skip event
                            ref.read(analyticsProvider.notifier).trackPlayerEvent(
                              action: 'skip',
                              trackId: currentTrack.id.toString(),
                              trackName: currentTrack.name,
                              artistName: currentTrack.artists
                                  .map((a) => a.name)
                                  .join(', '),
                            );
                          }
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

  Widget _artBox() => Container(
        width: 44,
        height: 44,
        color: Colors.grey[700],
        child: const Icon(Icons.music_note, size: 22, color: Colors.white54),
      );
}
