import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/player_provider.dart';

/// Queue view widget showing upcoming songs
class QueueView extends ConsumerWidget {
  const QueueView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);

    if (playerState.queue.isEmpty) {
      return Center(
        child: Text(
          'Queue is empty',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ListView.builder(
      itemCount: playerState.queue.length,
      itemBuilder: (context, index) {
        final track = playerState.queue[index];
        final isCurrentTrack = playerState.currentTrack?.id == track.id;

        return ListTile(
          leading: isCurrentTrack
              ? const Icon(Icons.music_note, color: Colors.green)
              : Text(
                  '${index + 1}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
          title: Text(
            track.name,
            style: TextStyle(
              fontWeight: isCurrentTrack ? FontWeight.w600 : FontWeight.normal,
              color: isCurrentTrack ? Colors.green : null,
            ),
          ),
          subtitle: Text(
            track.artists.map((a) => a.name).join(', '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () {
              // Remove from queue
            },
          ),
          onTap: () {
            if (index < playerState.queue.length) {
              ref.read(playerProvider.notifier).loadQueue(
                    playerState.queue,
                    startIndex: index,
                  );
            }
          },
        );
      },
    );
  }
}
