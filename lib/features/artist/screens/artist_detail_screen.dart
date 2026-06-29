import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elsfm/data/models/track.dart';
import 'package:elsfm/features/player/providers/player_notifier.dart';
import '../providers/artist_detail_provider.dart';
import '../../player/widgets/track_context_menu.dart';
import '../../../data/providers/api_client_provider.dart';

final _artistBioProvider = FutureProvider.family<String?, int>((ref, id) {
  return ref.watch(apiClientProvider).getArtistBio(id);
});

final _similarArtistsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, id) {
  return ref.watch(apiClientProvider).getSimilarArtists(id);
});

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
              // Bio section
              SliverToBoxAdapter(
                child: _ArtistBioSection(artistId: artistId),
              ),
              // Similar artists section
              SliverToBoxAdapter(
                child: _SimilarArtistsSection(artistId: artistId),
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

class _ArtistBioSection extends ConsumerStatefulWidget {
  final int artistId;
  const _ArtistBioSection({required this.artistId});

  @override
  ConsumerState<_ArtistBioSection> createState() => _ArtistBioSectionState();
}

class _ArtistBioSectionState extends ConsumerState<_ArtistBioSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final bioAsync = ref.watch(_artistBioProvider(widget.artistId));

    return bioAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (bio) {
        if (bio == null || bio.trim().isEmpty) return const SizedBox.shrink();
        // Strip HTML tags for plain display
        final plain = bio.replaceAll(RegExp(r'<[^>]+>'), '').trim();
        if (plain.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              AnimatedCrossFade(
                firstChild: Text(
                  plain,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(height: 1.5),
                ),
                secondChild: Text(
                  plain,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(height: 1.5),
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _expanded ? 'Show less' : 'Read more',
                    style: const TextStyle(
                      color: Color(0xFF689F38),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SimilarArtistsSection extends ConsumerWidget {
  final int artistId;
  const _SimilarArtistsSection({required this.artistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final simAsync = ref.watch(_similarArtistsProvider(artistId));

    return simAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (artists) {
        if (artists.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'Similar Artists',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 110,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: artists.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final a = artists[i];
                  final imgRaw = a['image_small'] as String?;
                  final imgUrl = _resolveImg(imgRaw);
                  final name = a['name'] as String? ?? '';
                  final id = a['id'] as int? ?? 0;
                  return GestureDetector(
                    onTap: () {
                      if (id > 0) Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => ArtistDetailScreen(artistId: id),
                      ));
                    },
                    child: SizedBox(
                      width: 80,
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: Colors.grey.shade800,
                            backgroundImage:
                                imgUrl != null ? NetworkImage(imgUrl) : null,
                            child: imgUrl == null
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            name,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String? _resolveImg(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    return 'https://www.elsfm.com/$raw';
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatDuration(track.duration),
            style: TextStyle(fontSize: 12, color: colorScheme.outline),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 20),
            onPressed: () => showTrackContextSheet(context, track),
          ),
        ],
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
