import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/player_notifier.dart';

/// Queue view — shows the full playback queue, highlights the current track,
/// and lets the user tap to jump to any track or swipe/tap × to remove one.
class QueueView extends ConsumerWidget {
  final ScrollController? scrollController;

  const QueueView({super.key, this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final tracks = playerState.tracks;

    if (tracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.queue_music, size: 48,
                color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 12),
            Text('Queue is empty',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Up Next (${tracks.length})',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];
              final isCurrent = playerState.currentIndex == index;
              final accent = Theme.of(context).colorScheme.primary;

              return Dismissible(
                key: ValueKey('${track.id}_$index'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: Colors.red.withOpacity(0.8),
                  child: const Icon(Icons.delete_outline,
                      color: Colors.white),
                ),
                onDismissed: (_) {
                  ref
                      .read(playerProvider.notifier)
                      .removeFromQueue(index);
                },
                child: ListTile(
                  key: ValueKey(track.id),
                  leading: isCurrent
                      ? Icon(Icons.equalizer, color: accent)
                      : Text(
                          '${index + 1}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                  title: Text(
                    track.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: isCurrent
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isCurrent ? accent : null,
                    ),
                  ),
                  subtitle: Text(
                    track.artists.map((a) => a.name).join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Remove from queue',
                    onPressed: () {
                      ref
                          .read(playerProvider.notifier)
                          .removeFromQueue(index);
                    },
                  ),
                  onTap: () {
                    ref
                        .read(playerProvider.notifier)
                        .setQueue(tracks, startIndex: index);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
