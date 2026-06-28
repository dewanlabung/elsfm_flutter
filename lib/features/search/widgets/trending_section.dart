import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/search_state.dart';
import '../../player/providers/player_notifier.dart';

class TrendingSection extends ConsumerWidget {
  final TrendingResults trending;

  const TrendingSection({super.key, required this.trending});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (trending.songs.isNotEmpty) ...[
          Text(
            'Trending Songs',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...trending.songs.asMap().entries.map((entry) {
            final index = entry.key;
            final song = entry.value;
            final img = song.image;
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: img != null && img.isNotEmpty
                    ? Image.network(
                        img,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _NumBox(num: index + 1),
                      )
                    : _NumBox(num: index + 1),
              ),
              title: Text(song.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                song.artists.map((a) => a.name).join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                ref
                    .read(playerProvider.notifier)
                    .setQueue(trending.songs, startIndex: index);
                context.push('/now-playing');
              },
            );
          }),
          const SizedBox(height: 24),
        ],
        if (trending.artists.isNotEmpty) ...[
          Text(
            'Trending Artists',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: trending.artists.length,
              itemBuilder: (context, index) {
                final artist = trending.artists[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () => context.push('/artist/${artist.id}'),
                    child: SizedBox(
                      width: 90,
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage:
                                (artist.image != null && artist.image!.isNotEmpty)
                                    ? NetworkImage(artist.image!)
                                    : null,
                            backgroundColor: Colors.grey[300],
                            child: (artist.image == null || artist.image!.isEmpty)
                                ? const Icon(Icons.person, size: 32)
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            artist.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _NumBox extends StatelessWidget {
  final int num;
  const _NumBox({required this.num});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Text('$num', style: Theme.of(context).textTheme.labelMedium),
      ),
    );
  }
}
