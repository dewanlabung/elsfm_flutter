import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/track.dart';
import '../../../data/models/album.dart';
import '../../../data/providers/api_client_provider.dart';
import '../../player/providers/player_notifier.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final _albumDetailProvider =
    FutureProvider.family<_AlbumDetail, int>((ref, id) async {
  final api = ref.watch(apiClientProvider);
  final raw = await api.getAlbum(id);
  final albumData = raw['album'] as Map<String, dynamic>? ?? raw;

  final album = Album.fromJson(albumData);

  final tracksRaw =
      ((albumData['tracks']?['data'] ?? []) as List);
  final tracks = tracksRaw
      .map((e) => Track.fromJson(e as Map<String, dynamic>))
      .toList();

  return _AlbumDetail(album: album, tracks: tracks);
});

class _AlbumDetail {
  final Album album;
  final List<Track> tracks;

  const _AlbumDetail({required this.album, required this.tracks});
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class AlbumDetailScreen extends ConsumerWidget {
  final int albumId;

  const AlbumDetailScreen({super.key, required this.albumId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(_albumDetailProvider(albumId));

    return Scaffold(
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to load album',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('$err',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.invalidate(_albumDetailProvider(albumId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (detail) => _AlbumDetailBody(detail: detail),
      ),
    );
  }
}

class _AlbumDetailBody extends ConsumerWidget {
  final _AlbumDetail detail;

  const _AlbumDetailBody({required this.detail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final album = detail.album;
    final artistNames = album.artists.map((a) => a.name).join(', ');
    final subtitle = [
      if (artistNames.isNotEmpty) artistNames,
      if (album.releaseYear != null) '${album.releaseYear}',
    ].join(' · ');

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              album.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (album.image != null)
                  Image.network(
                    album.image!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: const Icon(Icons.album, size: 80),
                    ),
                  )
                else
                  Container(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: const Icon(Icons.album, size: 80),
                  ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Artist / year subtitle + Play All
        SliverToBoxAdapter(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                              ),
                        ),
                      Text(
                        '${detail.tracks.length} tracks',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                            ),
                      ),
                    ],
                  ),
                ),
                if (detail.tracks.isNotEmpty)
                  FilledButton.icon(
                    onPressed: () {
                      ref
                          .read(playerProvider.notifier)
                          .setQueue(detail.tracks, startIndex: 0);
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play All'),
                  ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final track = detail.tracks[index];
              return _TrackRow(
                track: track,
                index: index,
                allTracks: detail.tracks,
              );
            },
            childCount: detail.tracks.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

class _TrackRow extends ConsumerWidget {
  final Track track;
  final int index;
  final List<Track> allTracks;

  const _TrackRow({
    required this.track,
    required this.index,
    required this.allTracks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistNames =
        track.artists.map((a) => a.name).join(', ');
    final durationStr = _formatDuration(track.duration);

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 44,
          height: 44,
          child: track.image != null
              ? Image.network(
                  track.image!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: const Icon(Icons.music_note, size: 20),
                  ),
                )
              : Container(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: const Icon(Icons.music_note, size: 20),
                ),
        ),
      ),
      title: Text(
        track.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        artistNames,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            durationStr,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.5),
                ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            onPressed: () {
              ref
                  .read(playerProvider.notifier)
                  .setQueue(allTracks, startIndex: index);
            },
          ),
        ],
      ),
      onTap: () {
        ref
            .read(playerProvider.notifier)
            .setQueue(allTracks, startIndex: index);
      },
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inSeconds ~/ 60;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
