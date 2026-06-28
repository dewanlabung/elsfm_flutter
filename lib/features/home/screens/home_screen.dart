import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/genre.dart';
import '../../../data/models/playlist.dart';
import '../../../data/models/track.dart';
import '../../../config/app_config.dart';
import '../providers/home_provider.dart';
import '../../player/providers/player_notifier.dart';

String _formatDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final m = totalSeconds ~/ 60;
  final s = totalSeconds % 60;
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
            icon: const Icon(Icons.favorite),
            onPressed: () => context.go('/library'),
            tooltip: 'Library',
          ),
        ],
      ),
      body: homeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Failed to load home content',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '$err',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(homeDataProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (home) => SingleChildScrollView(
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
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

// ── Playlists ────────────────────────────────────────────────────────────────

class _PlaylistRow extends StatelessWidget {
  const _PlaylistRow({required this.playlists});

  final List<Playlist> playlists;

  @override
  Widget build(BuildContext context) {
    if (playlists.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('No playlists available.'),
      );
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
  const _PlaylistCard({required this.playlist});

  final Playlist playlist;

  Color _placeholderColor() {
    final hue =
        (playlist.name.codeUnits.fold(0, (a, b) => a + b) % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.4, 0.35).toColor();
  }

  String? _imageUrl() {
    final img = playlist.image;
    if (img == null || img.isEmpty) return null;
    if (img.startsWith('http')) return img;
    return '${AppConfig.webBaseUrl}/$img';
  }

  @override
  Widget build(BuildContext context) {
    const double size = 120;
    final imageUrl = _imageUrl();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _ColoredPlaceholder(
                      color: _placeholderColor(),
                      size: size,
                    ),
                  )
                : _ColoredPlaceholder(
                    color: _placeholderColor(),
                    size: size,
                  ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: size,
            child: Text(
              playlist.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Genres ───────────────────────────────────────────────────────────────────

class _GenreRow extends StatelessWidget {
  const _GenreRow({required this.genres});

  final List<Genre> genres;

  @override
  Widget build(BuildContext context) {
    if (genres.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('No genres available.'),
      );
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
  const _GenreChip({required this.genre});

  final Genre genre;

  Color _chipColor() {
    final hue =
        (genre.name.codeUnits.fold(0, (a, b) => a + b) % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.45, 0.38).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(
          genre.label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        backgroundColor: _chipColor(),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}

// ── Tracks ───────────────────────────────────────────────────────────────────

class _TrackList extends StatelessWidget {
  const _TrackList({required this.tracks});

  final List<Track> tracks;

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('No tracks available.'),
      );
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
  const _TrackTile({required this.track, required this.index});

  final Track track;
  final int index;

  String? _imageUrl() {
    final img = track.image;
    if (img == null || img.isEmpty) return null;
    if (img.startsWith('http')) return img;
    return '${AppConfig.webBaseUrl}/$img';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = _imageUrl();
    final artistNames = track.artists.map((a) => a.name).join(', ');
    final duration = _formatDuration(track.duration);

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: imageUrl != null
            ? Image.network(
                imageUrl,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _TrackPlaceholder(index: index),
              )
            : _TrackPlaceholder(index: index),
      ),
      title: Text(
        track.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: artistNames.isNotEmpty
          ? Text(
              artistNames,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Text(
        duration,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: () {
        ref.read(playerProvider.notifier).playTrack(track);
      },
    );
  }
}

class _TrackPlaceholder extends StatelessWidget {
  const _TrackPlaceholder({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Text(
          '$index',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}

class _ColoredPlaceholder extends StatelessWidget {
  const _ColoredPlaceholder({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: color,
      child: const Center(
        child: Icon(Icons.music_note, color: Colors.white70, size: 40),
      ),
    );
  }
}
