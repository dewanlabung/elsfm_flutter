import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/player_notifier.dart';

/// Queue view widget showing upcoming songs
class QueueView extends ConsumerWidget {
  final ScrollController? scrollController;

  const QueueView({super.key, this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final tracks = playerState.tracks;

    if (tracks.isEmpty) {
      return Center(
        child: Text(
          'Queue is empty',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        final isCurrentTrack = playerState.currentIndex == index;

        return ListTile(
          key: ValueKey(track.id),
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
            ref.read(playerProvider.notifier).setQueue(tracks, startIndex: index);
          },
        );
      },
    );
  }
}
