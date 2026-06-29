import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:elsfm/features/auth/providers/auth_notifier.dart';
import 'package:elsfm/features/auth/models/auth_state.dart';
import 'package:elsfm/features/player/providers/player_notifier.dart';
import 'package:elsfm/config/app_config.dart';
import '../providers/library_provider.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    (label: 'PLAYLISTS', icon: Icons.playlist_play),
    (label: 'SONGS', icon: Icons.music_note),
    (label: 'ARTISTS', icon: Icons.person),
    (label: 'ALBUMS', icon: Icons.album),
    (label: 'GENRES', icon: Icons.category),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (authState.state != AuthState.authenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Library')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Please log in to access your library'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamed('/login'),
                child: const Text('Log In'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go('/search'),
            tooltip: 'Search',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: _tabs
              .map((t) => Tab(text: t.label))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _PlaylistsTab(),
          _SongsTab(),
          _ArtistsTab(),
          _AlbumsTab(),
          _GenresTab(),
        ],
      ),
    );
  }
}

// ── PLAYLISTS ────────────────────────────────────────────────────────────────

class _PlaylistsTab extends ConsumerWidget {
  const _PlaylistsTab();

  String? _img(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    return '${AppConfig.webBaseUrl}/$raw';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(userPlaylistsProvider);
    return playlistsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _EmptyState(
        icon: Icons.playlist_play,
        message: 'No playlists yet',
        hint: 'Create a playlist to organize your music',
      ),
      data: (playlists) {
        if (playlists.isEmpty) {
          return _EmptyState(
            icon: Icons.playlist_play,
            message: 'No playlists yet',
            hint: 'Create a playlist to organize your music',
          );
        }
        return ListView.builder(
          itemCount: playlists.length,
          itemBuilder: (context, i) {
            final p = playlists[i];
            final img = _img(p.image);
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: img != null
                    ? Image.network(img, width: 44, height: 44, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _artBox())
                    : _artBox(),
              ),
              title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => context.push('/playlist/${p.id}'),
            );
          },
        );
      },
    );
  }

  Widget _artBox() => Container(
        width: 44, height: 44,
        color: Colors.grey.shade300,
        child: const Icon(Icons.queue_music, size: 22, color: Colors.grey),
      );
}

// ── SONGS ────────────────────────────────────────────────────────────────────

class _SongsTab extends ConsumerWidget {
  const _SongsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(likedTracksProvider);

    return tracksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _EmptyState(
        icon: Icons.error_outline,
        message: 'Could not load songs',
        hint: e.toString(),
      ),
      data: (tracks) {
        if (tracks.isEmpty) {
          return _EmptyState(
            icon: Icons.favorite_border,
            message: 'No liked songs yet',
            hint: 'Heart a song to save it here',
          );
        }
        return ListView.builder(
          itemCount: tracks.length,
          itemBuilder: (context, i) {
            final track = tracks[i];
            return ListTile(
              leading: _TrackArt(imageUrl: track.image),
              title: Text(track.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                track.artists.map((a) => a.name).join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.more_vert),
              onTap: () {
                ref.read(playerProvider.notifier).setQueue(tracks, startIndex: i);
                context.push('/now-playing');
              },
            );
          },
        );
      },
    );
  }
}

// ── ARTISTS ──────────────────────────────────────────────────────────────────

class _ArtistsTab extends ConsumerWidget {
  const _ArtistsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistsAsync = ref.watch(followedArtistsProvider);
    return artistsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _EmptyState(
        icon: Icons.person_outline,
        message: 'No followed artists',
        hint: 'Follow artists to see them here',
      ),
      data: (artists) {
        if (artists.isEmpty) {
          return _EmptyState(
            icon: Icons.person_outline,
            message: 'No followed artists',
            hint: 'Follow artists to see them here',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: artists.length,
          itemBuilder: (context, i) {
            final artist = artists[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    artist.image != null ? NetworkImage(artist.image!) : null,
                child: artist.image == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(artist.name),
              onTap: () => context.push('/artists/${artist.id}'),
            );
          },
        );
      },
    );
  }
}

// ── ALBUMS ───────────────────────────────────────────────────────────────────

class _AlbumsTab extends ConsumerWidget {
  const _AlbumsTab();

  String? _img(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    return '${AppConfig.webBaseUrl}/$raw';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(likedAlbumsProvider);
    return albumsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _EmptyState(
        icon: Icons.album_outlined,
        message: 'No saved albums',
        hint: 'Save albums to access them quickly',
      ),
      data: (albums) {
        if (albums.isEmpty) {
          return _EmptyState(
            icon: Icons.album_outlined,
            message: 'No saved albums',
            hint: 'Save albums to access them quickly',
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemCount: albums.length,
          itemBuilder: (context, i) {
            final album = albums[i];
            final img = _img(album.image);
            return GestureDetector(
              onTap: () => context.push('/album/${album.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: img != null
                          ? Image.network(img, fit: BoxFit.cover, width: double.infinity,
                              errorBuilder: (_, __, ___) => _albumBox())
                          : _albumBox(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(album.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  if (album.artists.isNotEmpty)
                    Text(album.artists[0].name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _albumBox() => Container(
        color: Colors.grey.shade300,
        child: const Center(child: Icon(Icons.album, size: 40, color: Colors.grey)),
      );
}

// ── GENRES ───────────────────────────────────────────────────────────────────

class _GenresTab extends ConsumerWidget {
  const _GenresTab();

  static const _palette = [
    Colors.pink, Colors.red, Colors.orange, Colors.purple,
    Colors.blue, Colors.brown, Colors.indigo, Colors.green,
    Colors.teal, Colors.cyan, Colors.amber, Colors.deepOrange,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genresAsync = ref.watch(genresProvider);
    return genresAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load genres\n$e', textAlign: TextAlign.center)),
      data: (genres) {
        if (genres.isEmpty) {
          return const Center(child: Text('No genres available'));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
          ),
          itemCount: genres.length,
          itemBuilder: (context, i) {
            final genre = genres[i];
            final color = _palette[i % _palette.length];
            return _GenreCard(name: genre.label, color: color, imageUrl: genre.image);
          },
        );
      },
    );
  }
}

class _GenreCard extends StatelessWidget {
  final String name;
  final Color color;
  final String? imageUrl;

  const _GenreCard({required this.name, required this.color, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    imageUrl!,
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.music_note, color: color, size: 28),
                  ),
                )
              else
                Icon(Icons.music_note, color: color, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const _SectionHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleSmall),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String hint;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackArt extends StatelessWidget {
  final String? imageUrl;

  const _TrackArt({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          imageUrl!,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.music_note, size: 22, color: Colors.grey),
      );
}
