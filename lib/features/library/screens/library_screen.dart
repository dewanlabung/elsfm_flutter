import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/library_provider.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Liked Tracks'),
            Tab(text: 'Liked Albums'),
            Tab(text: 'Playlists'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Liked Tracks Tab
          _buildLikedTracksTab(),
          // Liked Albums Tab
          _buildLikedAlbumsTab(),
          // Playlists Tab
          _buildPlaylistsTab(),
        ],
      ),
    );
  }

  Widget _buildLikedTracksTab() {
    return ref.watch(likedTracksProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text('Error: $err')),
      data: (tracks) {
        if (tracks.isEmpty) {
          return const Center(child: Text('No liked tracks yet'));
        }
        return ListView.builder(
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            final track = tracks[index];
            return ListTile(
              title: Text(track.name),
              subtitle: Text(
                track.artists.isNotEmpty
                    ? track.artists.map((a) => a.name).join(', ')
                    : 'Unknown',
              ),
              trailing: Text(
                '${track.duration.inMinutes}:${(track.duration.inSeconds % 60).toString().padLeft(2, '0')}',
              ),
              onTap: () {
                // TODO: Navigate to track detail or play track
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLikedAlbumsTab() {
    return ref.watch(likedAlbumsProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text('Error: $err')),
      data: (albums) {
        if (albums.isEmpty) {
          return const Center(child: Text('No liked albums yet'));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.0,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];
            return GestureDetector(
              onTap: () => context.go('/album/${album.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1DB954).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(Icons.album, color: Color(0xFF1DB954), size: 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    album.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlaylistsTab() {
    return ref.watch(userPlaylistsProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text('Error: $err')),
      data: (playlists) {
        if (playlists.isEmpty) {
          return const Center(child: Text('No playlists yet'));
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
                  color: const Color(0xFF1DB954).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: Icon(Icons.playlist_play, color: Color(0xFF1DB954)),
                ),
              ),
              title: Text(playlist.name),
              subtitle: Text('${playlist.trackCount} tracks'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/playlist/${playlist.id}'),
            );
          },
        );
      },
    );
  }
}
