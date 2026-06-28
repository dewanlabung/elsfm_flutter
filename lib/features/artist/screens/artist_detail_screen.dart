import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elsfm/data/models/track.dart';
import 'package:elsfm/features/player/providers/player_notifier.dart';
import '../providers/artist_detail_provider.dart';

class ArtistDetailScreen extends ConsumerWidget {
  final int artistId;

  const ArtistDetailScreen({super.key, required this.artistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(artistDetailProvider(artistId));

    return dataAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Artist')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (data) {
        final artist = data['artist'] as Map<String, dynamic>? ?? {};
        final tracks = data['tracks'] as List<Track>? ?? [];
        final name = artist['name'] as String? ?? 'Artist';
        final imageRaw = artist['image_small'] as String? ?? artist['image'] as String?;
        final imageUrl = _resolveUrl(imageRaw);

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imageUrl != null)
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _artistPlaceholder(),
                        )
                      else
                        _artistPlaceholder(),
                      // Gradient overlay for title legibility
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black54],
                            stops: [0.5, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text(
                    'Popular Songs',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
              if (tracks.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No tracks found')),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final track = tracks[i];
                      return _TrackTile(
                        track: track,
                        index: i,
                        onTap: () {
                          ref
                              .read(playerProvider.notifier)
                              .setQueue(tracks, startIndex: i);
                        },
                      );
                    },
                    childCount: tracks.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  String? _resolveUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return 'https://www.elsfm.com/$raw';
  }

  Widget _artistPlaceholder() {
    return Container(
      color: Colors.grey.withOpacity(0.3),
      child: const Icon(Icons.person, size: 80, color: Colors.grey),
    );
  }
}

class _TrackTile extends StatelessWidget {
  final Track track;
  final int index;
  final VoidCallback onTap;

  const _TrackTile({
    required this.track,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final playsLabel = track.plays > 0 ? '${track.plays} plays' : '';

    return ListTile(
      leading: _TrackThumbnail(imageUrl: track.image),
      title: Text(track.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: playsLabel.isNotEmpty
          ? Text(
              playsLabel,
              style: TextStyle(fontSize: 12, color: colorScheme.outline),
            )
          : null,
      trailing: Text(
        _formatDuration(track.duration),
        style: TextStyle(fontSize: 12, color: colorScheme.outline),
      ),
      onTap: onTap,
    );
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes;
    final secs = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}

class _TrackThumbnail extends StatelessWidget {
  final String? imageUrl;

  const _TrackThumbnail({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: 44,
        height: 44,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(context),
              )
            : _fallback(context),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.music_note,
        size: 22,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}
