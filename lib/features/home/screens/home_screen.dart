import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/track.dart';
import '../../../data/models/playlist.dart';
import '../../../data/models/genre.dart';
import '../../../config/app_config.dart';
import '../providers/home_provider.dart';
import '../../player/providers/player_notifier.dart';

String _fmtDuration(Duration d) {
  final m = d.inSeconds ~/ 60;
  final s = d.inSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(homeDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ELSFM'),
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
              Text('$err', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
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
                _SectionHeader(title: 'Featured Playlists'),
                _PlaylistRow(playlists: home.featuredPlaylists),
                const SizedBox(height: 8),
                _SectionHeader(title: 'Browse by Genre'),
                _GenreRow(genres: home.genres),
                const SizedBox(height: 8),
                _SectionHeader(title: 'Popular Songs'),
                _TrackList(tracks: home.topTracks),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
      return const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('No playlists available.'));
    }
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: playlists.length,
        itemBuilder: (_, i) => _PlaylistCard(playlist: playlists[i]),
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  const _PlaylistCard({required this.playlist});

  Color get _color {
    final hue = (playlist.name.codeUnits.fold(0, (a, b) => a + b) % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.4, 0.35).toColor();
  }

  String? get _img {
    final img = playlist.image;
    if (img == null || img.isEmpty) return null;
    if (img.startsWith('http')) return img;
    return '${AppConfig.webBaseUrl}/$img';
  }

  @override
  Widget build(BuildContext context) {
    const size = 120.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _img != null
                ? Image.network(_img!, width: size, height: size, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _ColorBox(color: _color, size: size))
                : _ColorBox(color: _color, size: size),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: size,
            child: Text(playlist.name,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall),
          ),
        ],
      ),
    );
  }
}

// ── Genres ────────────────────────────────────────────────────────────────────

class _GenreRow extends StatelessWidget {
  final List<Genre> genres;
  const _GenreRow({required this.genres});

  @override
  Widget build(BuildContext context) {
    if (genres.isEmpty) {
      return const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('No genres available.'));
    }
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: genres.length,
        itemBuilder: (_, i) => _GenreChip(genre: genres[i]),
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  final Genre genre;
  const _GenreChip({required this.genre});

  Color get _color {
    final hue = (genre.name.codeUnits.fold(0, (a, b) => a + b) % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.45, 0.38).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(genre.label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        backgroundColor: _color,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 4),
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
      return const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('No tracks available.'));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tracks.length,
      itemBuilder: (_, i) => _TrackTile(track: tracks[i], index: i + 1),
    );
  }
}

class _TrackTile extends ConsumerWidget {
  final Track track;
  final int index;
  const _TrackTile({required this.track, required this.index});

  String? get _img {
    final img = track.image;
    if (img == null || img.isEmpty) return null;
    if (img.startsWith('http')) return img;
    return '${AppConfig.webBaseUrl}/$img';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = _img;
    final artists = track.artists.map((a) => a.name).join(', ');

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: imageUrl != null
            ? Image.network(imageUrl, width: 44, height: 44, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _NumberBox(index: index, ctx: context))
            : _NumberBox(index: index, ctx: context),
      ),
      title: Text(track.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: artists.isNotEmpty
          ? Text(artists, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: Text(_fmtDuration(track.duration), style: Theme.of(context).textTheme.bodySmall),
      onTap: () => ref.read(playerProvider.notifier).playTrack(track),
    );
  }
}

class _ColorBox extends StatelessWidget {
  final Color color;
  final double size;
  const _ColorBox({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size, color: color,
      child: const Center(child: Icon(Icons.music_note, color: Colors.white70, size: 40)),
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
      width: 44, height: 44,
      color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
      child: Center(child: Text('$index', style: Theme.of(ctx).textTheme.labelSmall)),
    );
  }
}
