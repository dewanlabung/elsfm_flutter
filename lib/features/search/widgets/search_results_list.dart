import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/search_state.dart';
import 'package:elsfm/data/models/track.dart';
import 'package:elsfm/features/player/providers/player_notifier.dart';

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
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Songs (${state.results?.songs.length ?? 0})'),
              Tab(text: 'Artists (${state.results?.artists.length ?? 0})'),
              Tab(text: 'Playlists (${state.results?.playlists.length ?? 0})'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Songs tab
                _buildSongsList(state.results?.songs ?? [], ref),
                // Artists tab
                _buildArtistsList(state.results?.artists ?? []),
                // Playlists tab
                _buildPlaylistsList(state.results?.playlists ?? []),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongsList(List<Track> songs, WidgetRef ref) {
    if (songs.isEmpty) {
      return const Center(child: Text('No songs found'));
    }

    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.music_note),
          ),
          title: Text(song.name),
          subtitle: Text(
            song.artists.map((a) => a.name).join(', '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text('${song.duration.inMinutes}:${(song.duration.inSeconds % 60).toString().padLeft(2, '0')}'),
          onTap: () {
            ref.read(playerProvider.notifier).playTrack(song);
          },
        );
      },
    );
  }

  Widget _buildArtistsList(List<dynamic> artists) {
    if (artists.isEmpty) {
      return const Center(child: Text('No artists found'));
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
      ),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        return Card(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 120,
                color: Colors.grey[300],
                child: artist.image != null && artist.image!.isNotEmpty
                    ? Image.network(
                        artist.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.person, size: 48);
                        },
                      )
                    : const Icon(Icons.person, size: 48),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  artist.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaylistsList(List<dynamic> playlists) {
    if (playlists.isEmpty) {
      return const Center(child: Text('No playlists found'));
    }

    return ListView.builder(
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.playlist_play),
          ),
          title: Text(playlist.name),
          subtitle: Text('${playlist.trackCount} songs'),
          onTap: () {
            // Open playlist
          },
        );
      },
    );
  }
}
