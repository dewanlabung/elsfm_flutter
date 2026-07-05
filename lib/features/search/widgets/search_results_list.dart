import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/search_state.dart';
import 'package:elsfm/data/models/track.dart';
import 'package:elsfm/data/models/artist.dart';
import 'package:elsfm/data/models/album.dart';
import 'package:elsfm/data/models/playlist.dart';
import 'package:elsfm/features/player/providers/player_notifier.dart';
import '../../player/widgets/track_context_menu.dart';

class SearchResultsList extends ConsumerWidget {
  final SearchState state;

  const SearchResultsList({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Songs (${state.results?.songs.length ?? 0})'),
              Tab(text: 'Artists (${state.results?.artists.length ?? 0})'),
              Tab(text: 'Albums (${state.results?.albums.length ?? 0})'),
              Tab(text: 'Playlists (${state.results?.playlists.length ?? 0})'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _SongsTab(songs: state.results?.songs ?? []),
                _ArtistsTab(artists: state.results?.artists ?? []),
                _AlbumsTab(albums: state.results?.albums ?? []),
                _PlaylistsTab(playlists: state.results?.playlists ?? []),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Songs ─────────────────────────────────────────────────────────────────────

class _SongsTab extends ConsumerWidget {
  final List<Track> songs;

  const _SongsTab({required this.songs});

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    if (songs.isEmpty) {
      return const Center(child: Text('No songs found'));
    }
    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        final img = song.image;
        final imgUrl = (img != null && img.isNotEmpty)
            ? (img.startsWith('http') ? img : img)
            : null;
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: imgUrl != null
                ? Image.network(imgUrl,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _iconBox(Icons.music_note))
                : _iconBox(Icons.music_note),
          ),
          title: Text(song.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            song.artists.map((a) => a.name).join(', '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            '${song.duration.inMinutes}:${(song.duration.inSeconds % 60).toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          onTap: () {
            widgetRef
                .read(playerProvider.notifier)
                .setQueue(songs, startIndex: index);
            context.push('/now-playing');
          },
        );
      },
    );
  }

  Widget _iconBox(IconData icon) => Container(
        width: 44,
        height: 44,
        color: Colors.grey[300],
        child: Icon(icon, color: Colors.grey[600]),
      );
}

// ── Artists ───────────────────────────────────────────────────────────────────

class _ArtistsTab extends StatelessWidget {
  final List<Artist> artists;
  const _ArtistsTab({required this.artists});

  @override
  Widget build(BuildContext context) {
    if (artists.isEmpty) {
      return const Center(child: Text('No artists found'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.82,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        return GestureDetector(
          onTap: () => context.push('/artist/${artist.id}'),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: artist.image != null && artist.image!.isNotEmpty
                      ? Image.network(
                          artist.image!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _ArtistPlaceholder(name: artist.name),
                        )
                      : _ArtistPlaceholder(name: artist.name),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                artist.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Albums ────────────────────────────────────────────────────────────────────

class _AlbumsTab extends StatelessWidget {
  final List<Album> albums;
  const _AlbumsTab({required this.albums});

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) {
      return const Center(child: Text('No albums found'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.82,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return GestureDetector(
          onTap: () => context.push('/album/${album.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: album.image != null && album.image!.isNotEmpty
                      ? Image.network(
                          album.image!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _AlbumPlaceholder(name: album.name),
                        )
                      : _AlbumPlaceholder(name: album.name),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                album.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
              ),
              if (album.artists.isNotEmpty)
                Text(
                  album.artists.map((a) => a.name).join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Playlists ─────────────────────────────────────────────────────────────────

class _PlaylistsTab extends StatelessWidget {
  final List<Playlist> playlists;
  const _PlaylistsTab({required this.playlists});

  @override
  Widget build(BuildContext context) {
    if (playlists.isEmpty) {
      return const Center(child: Text('No playlists found'));
    }
    return ListView.builder(
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        final img = playlist.image;
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: img != null && img.isNotEmpty
                ? Image.network(
                    img,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _iconBox(Icons.playlist_play),
                  )
                : _iconBox(Icons.playlist_play),
          ),
          title: Text(playlist.name,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${playlist.views} plays'),
          onTap: () => context.push('/playlist/${playlist.id}'),
        );
      },
    );
  }

  Widget _iconBox(IconData icon) => Container(
        width: 48,
        height: 48,
        color: Colors.grey[300],
        child: Icon(icon, color: Colors.grey[600]),
      );
}

// ── Placeholders ──────────────────────────────────────────────────────────────

class _ArtistPlaceholder extends StatelessWidget {
  final String name;
  const _ArtistPlaceholder({required this.name});

  Color get _color {
    final hue = (name.codeUnits.fold(0, (a, b) => a + b) % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.45, 0.3).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _color,
      child:
          const Center(child: Icon(Icons.person, size: 40, color: Colors.white54)),
    );
  }
}

class _AlbumPlaceholder extends StatelessWidget {
  final String name;
  const _AlbumPlaceholder({required this.name});

  Color get _color {
    final hue = (name.codeUnits.fold(0, (a, b) => a + b) % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.4, 0.3).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _color,
      child: const Center(
          child: Icon(Icons.album, size: 40, color: Colors.white54)),
    );
  }
}

/// Rectangular thumbnail with fallback icon.
class _Thumbnail extends StatelessWidget {
  final String? url;
  final double size;
  final IconData placeholder;

  const _Thumbnail({required this.url, required this.size, required this.placeholder});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: size,
        height: size,
        child: url != null && url!.isNotEmpty
            ? Image.network(
                url!,
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
      child: Icon(placeholder, size: size * 0.5, color: Theme.of(context).colorScheme.outline),
    );
  }
}

/// Circular thumbnail for artists.
class _CircularThumbnail extends StatelessWidget {
  final String? url;
  final double size;

  const _CircularThumbnail({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: url != null && url!.isNotEmpty
            ? Image.network(
                url!,
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
      child: Icon(Icons.person, size: size * 0.5, color: Theme.of(context).colorScheme.outline),
    );
  }
}
