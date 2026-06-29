import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/track.dart';
import '../../../data/models/playlist.dart';
import '../../../data/models/album.dart';
import '../providers/home_provider.dart';
import '../../player/providers/player_notifier.dart';
import '../../player/widgets/track_context_menu.dart';

String _fmtDuration(Duration d) {
  final m = d.inSeconds ~/ 60;
  final s = d.inSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

String _resolveImg(String? img) {
  if (img == null || img.isEmpty) return '';
  if (img.startsWith('http')) return img;
  return 'https://www.elsfm.com/$img';
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(homeDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nepali Christian Songs'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.library_music_outlined),
            onPressed: () => context.go('/library'),
            tooltip: 'Library',
          ),
        ],
      ),
      body: homeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to load', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('$err',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(homeDataProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (home) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(homeDataProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  title: 'Featured Playlists',
                  onSeeAll: () {},
                ),
                _PlaylistRow(playlists: home.featuredPlaylists),
                const SizedBox(height: 8),
                _SectionHeader(
                  title: 'Albums',
                  onSeeAll: () {},
                ),
                _AlbumRow(albums: home.albums),
                const SizedBox(height: 8),
                _SectionHeader(
                  title: 'Popular Songs',
                  onSeeAll: null,
                ),
                _TrackList(tracks: home.topTracks),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text('>'),
            ),
        ],
      ),
    );
  }
}

// ── Playlists ─────────────────────────────────────────────────────────────────

class _PlaylistRow extends StatelessWidget {
  final List<Playlist> playlists;
  const _PlaylistRow({required this.playlists});

  @override
  Widget build(BuildContext context) {
    if (playlists.isEmpty) {
      return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('No playlists available.'));
    }
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: playlists.length,
        itemBuilder: (_, i) => _MediaCard(
          imageUrl: _resolveImg(playlists[i].image),
          title: playlists[i].name,
          subtitle: 'by elsfm',
          onTap: () => context.push('/playlist/${playlists[i].id}'),
          colorSeed: playlists[i].name,
        ),
      ),
    );
  }
}

// ── Albums ─────────────────────────────────────────────────────────────────────

class _AlbumRow extends StatelessWidget {
  final List<Album> albums;
  const _AlbumRow({required this.albums});

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) {
      return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('No albums available.'));
    }
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: albums.length,
        itemBuilder: (_, i) {
          final album = albums[i];
          final artistName =
              album.artists.isNotEmpty ? album.artists.first.name : 'elsfm';
          return _MediaCard(
            imageUrl: _resolveImg(album.image),
            title: album.name,
            subtitle: artistName,
            onTap: () => context.push('/album/${album.id}'),
            colorSeed: album.name,
          );
        },
      ),
    );
  }
}

// ── Shared media card ─────────────────────────────────────────────────────────

class _MediaCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String colorSeed;

  const _MediaCard({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.colorSeed,
  });

  Color get _fallbackColor {
    final hue =
        (colorSeed.codeUnits.fold(0, (a, b) => a + b) % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.4, 0.35).toColor();
  }

  @override
  Widget build(BuildContext context) {
    const size = 120.0;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: size,
                          height: size,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _ColorBox(color: _fallbackColor, size: size),
                        )
                      : _ColorBox(color: _fallbackColor, size: size),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: size,
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            SizedBox(
              width: size,
              child: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tracks ────────────────────────────────────────────────────────────────────

class _TrackList extends StatelessWidget {
  final List<Track> tracks;
  const _TrackList({required this.tracks});

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('No tracks available.'));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tracks.length,
      itemBuilder: (_, i) => _TrackTile(track: tracks[i], index: i, allTracks: tracks),
    );
  }
}

class _TrackTile extends ConsumerWidget {
  final Track track;
  final int index;
  final List<Track> allTracks;
  const _TrackTile(
      {required this.track, required this.index, required this.allTracks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = _resolveImg(track.image);
    final artists = track.artists.map((a) => a.name).join(', ');

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _NumberBox(index: index + 1, ctx: context),
              )
            : _NumberBox(index: index + 1, ctx: context),
      ),
      title: Text(track.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: artists.isNotEmpty
          ? Text(artists, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_fmtDuration(track.duration),
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.more_vert,
                size: 20,
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
            onPressed: () => showTrackContextSheet(context, track),
          ),
        ],
      ),
      onTap: () => ref
          .read(playerProvider.notifier)
          .setQueue(allTracks, startIndex: index),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _ColorBox extends StatelessWidget {
  final Color color;
  final double size;
  const _ColorBox({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: color,
      child: const Center(
          child: Icon(Icons.music_note, color: Colors.white70, size: 40)),
    );
  }
}

class _NumberBox extends StatelessWidget {
  final int index;
  final BuildContext ctx;
  const _NumberBox({required this.index, required this.ctx});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
      child: Center(
          child:
              Text('$index', style: Theme.of(ctx).textTheme.labelSmall)),
    );
  }
}
