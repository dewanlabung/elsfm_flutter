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

/// Search results display widget
class SearchResultsList extends ConsumerWidget {
  final SearchState state;

  const SearchResultsList({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
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
                _buildSongsList(context, state.results?.songs ?? [], ref),
                _buildArtistsList(context, state.results?.artists ?? []),
                _buildAlbumsList(context, state.results?.albums ?? []),
                _buildPlaylistsList(context, state.results?.playlists ?? []),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongsList(BuildContext context, List<Track> songs, WidgetRef ref) {
    if (songs.isEmpty) {
      return const Center(child: Text('No songs found'));
    }

    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return ListTile(
          leading: _Thumbnail(url: song.image, size: 44, placeholder: Icons.music_note),
          title: Text(song.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            song.artists.map((a) => a.name).join(', '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${song.duration.inMinutes}:${(song.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                onPressed: () => showTrackContextSheet(context, song),
              ),
            ],
          ),
          onTap: () {
            ref.read(playerProvider.notifier).playTrack(song);
          },
        );
      },
    );
  }

  Widget _buildArtistsList(BuildContext context, List<Artist> artists) {
    if (artists.isEmpty) {
      return const Center(child: Text('No artists found'));
    }

    return ListView.builder(
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        return ListTile(
          leading: _CircularThumbnail(url: artist.image, size: 44),
          title: Text(artist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () {
            context.push('/artist/${artist.id}');
          },
        );
      },
    );
  }

  Widget _buildAlbumsList(BuildContext context, List<Album> albums) {
    if (albums.isEmpty) {
      return const Center(child: Text('No albums found'));
    }

    return ListView.builder(
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return ListTile(
          leading: _Thumbnail(url: album.image, size: 44, placeholder: Icons.album),
          title: Text(album.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: album.artists.isNotEmpty
              ? Text(
                  album.artists.map((a) => a.name).join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          onTap: () {
            context.push('/album/${album.id}');
          },
        );
      },
    );
  }

  Widget _buildPlaylistsList(BuildContext context, List<Playlist> playlists) {
    if (playlists.isEmpty) {
      return const Center(child: Text('No playlists found'));
    }

    return ListView.builder(
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return ListTile(
          leading: _Thumbnail(url: playlist.image, size: 44, placeholder: Icons.playlist_play),
          title: Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${playlist.views} views'),
          onTap: () {
            context.push('/playlist/${playlist.id}');
          },
        );
      },
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
