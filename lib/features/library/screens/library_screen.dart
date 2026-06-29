import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:elsfm/features/auth/providers/auth_notifier.dart';
import 'package:elsfm/features/auth/models/auth_state.dart';
import 'package:elsfm/features/player/providers/player_notifier.dart';
import 'package:elsfm/features/downloads/providers/download_provider.dart';
import 'package:elsfm/config/app_config.dart';
import '../providers/library_provider.dart';
import 'package:elsfm/data/providers/api_client_provider.dart';

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
    (label: 'SONGS',     icon: Icons.favorite),
    (label: 'HISTORY',   icon: Icons.history),
    (label: 'ARTISTS',   icon: Icons.person),
    (label: 'ALBUMS',    icon: Icons.album),
    (label: 'DOWNLOADS', icon: Icons.download_done),
    (label: 'GENRES',    icon: Icons.category),
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
                onPressed: () => context.go('/home'),
                child: const Text('Go to Home'),
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(userPlaylistsProvider);
              ref.invalidate(likedTracksProvider);
              ref.invalidate(playHistoryProvider);
              ref.invalidate(followedArtistsProvider);
              ref.invalidate(likedAlbumsProvider);
              ref.invalidate(genresProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _PlaylistsTab(),
          _SongsTab(),
          _HistoryTab(),
          _ArtistsTab(),
          _AlbumsTab(),
          _DownloadsTab(),
          _GenresTab(),
        ],
      ),
    );
  }
}

// ── PLAYLISTS ────────────────────────────────────────────────────────────────

class _PlaylistsTab extends ConsumerWidget {
  const _PlaylistsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(userPlaylistsProvider);
    return Scaffold(
      body: playlistsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          message: 'Could not load playlists',
          detail: e.toString(),
          onRetry: () => ref.invalidate(userPlaylistsProvider),
        ),
        data: (playlists) {
          if (playlists.isEmpty) {
            return _EmptyState(
              icon: Icons.playlist_play,
              message: 'No playlists yet',
              hint: 'Tap + to create your first playlist',
            );
          }
          return ListView.builder(
            itemCount: playlists.length,
            itemBuilder: (context, i) {
              final p = playlists[i];
              return ListTile(
                leading: _ArtBox(imageUrl: _resolveImg(p.image), icon: Icons.queue_music),
                title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () => context.push('/playlist/${p.id}'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        tooltip: 'Create Playlist',
        onPressed: () => _showCreatePlaylistDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Playlist'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Playlist name',
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _create(ctx, ref, ctrl.text),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => _create(ctx, ref, ctrl.text),
              child: const Text('Create')),
        ],
      ),
    );
  }

  Future<void> _create(BuildContext ctx, WidgetRef ref, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    Navigator.pop(ctx);
    try {
      final api = ref.read(apiClientProvider);
      await api.createPlaylist(name: trimmed);
      ref.invalidate(userPlaylistsProvider);
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Failed to create playlist: $e')));
      }
    }
  }

  String? _resolveImg(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    return '${AppConfig.webBaseUrl}/$raw';
  }
}

// ── SONGS (Liked Tracks) ─────────────────────────────────────────────────────

class _SongsTab extends ConsumerWidget {
  const _SongsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(likedTracksProvider);
    return tracksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(
        message: 'Could not load liked songs',
        detail: e.toString(),
        onRetry: () => ref.invalidate(likedTracksProvider),
      ),
      data: (tracks) {
        if (tracks.isEmpty) {
          return const _EmptyState(
            icon: Icons.favorite_border,
            message: 'No liked songs yet',
            hint: 'Tap the heart on any song to save it here',
          );
        }
        return ListView.builder(
          itemCount: tracks.length,
          itemBuilder: (context, i) {
            final track = tracks[i];
            return ListTile(
              leading: _ArtBox(imageUrl: track.image, icon: Icons.music_note),
              title: Text(track.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                track.artists.map((a) => a.name).join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.more_vert, size: 18),
              onTap: () {
                ref
                    .read(playerProvider.notifier)
                    .setQueue(tracks, startIndex: i);
                context.push('/now-playing');
              },
            );
          },
        );
      },
    );
  }
}

// ── HISTORY ──────────────────────────────────────────────────────────────────

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(playHistoryProvider);
    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(
        message: 'Could not load history',
        detail: e.toString(),
        onRetry: () => ref.invalidate(playHistoryProvider),
      ),
      data: (tracks) {
        if (tracks.isEmpty) {
          return const _EmptyState(
            icon: Icons.history,
            message: 'No play history',
            hint: 'Songs you listen to will appear here',
          );
        }
        return ListView.builder(
          itemCount: tracks.length,
          itemBuilder: (context, i) {
            final track = tracks[i];
            return ListTile(
              leading: _ArtBox(imageUrl: track.image, icon: Icons.music_note),
              title: Text(track.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                track.artists.map((a) => a.name).join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                ref
                    .read(playerProvider.notifier)
                    .setQueue(tracks, startIndex: i);
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
      error: (e, _) => _ErrorState(
        message: 'Could not load artists',
        detail: e.toString(),
        onRetry: () => ref.invalidate(followedArtistsProvider),
      ),
      data: (artists) {
        if (artists.isEmpty) {
          return const _EmptyState(
            icon: Icons.person_outline,
            message: 'No followed artists',
            hint: 'Follow artists on their detail page to see them here',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: artists.length,
          itemBuilder: (context, i) {
            final artist = artists[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: artist.image != null
                    ? NetworkImage(artist.image!)
                    : null,
                child: artist.image == null
                    ? Text(artist.name.isNotEmpty
                        ? artist.name[0].toUpperCase()
                        : '?')
                    : null,
              ),
              title: Text(artist.name),
              trailing: const Icon(Icons.chevron_right, size: 18),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(likedAlbumsProvider);
    return albumsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(
        message: 'Could not load albums',
        detail: e.toString(),
        onRetry: () => ref.invalidate(likedAlbumsProvider),
      ),
      data: (albums) {
        if (albums.isEmpty) {
          return const _EmptyState(
            icon: Icons.album_outlined,
            message: 'No saved albums',
            hint: 'Like an album to save it here',
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
            final img = _resolveImg(album.image);
            return GestureDetector(
              onTap: () => context.push('/album/${album.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: img != null
                          ? Image.network(img,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) =>
                                  _albumFallback())
                          : _albumFallback(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(album.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  if (album.artists.isNotEmpty)
                    Text(album.artists[0].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _albumFallback() => Container(
        color: Colors.grey.shade300,
        child: const Center(
            child: Icon(Icons.album, size: 40, color: Colors.grey)));

  String? _resolveImg(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    return '${AppConfig.webBaseUrl}/$raw';
  }
}

// ── DOWNLOADS ────────────────────────────────────────────────────────────────

class _DownloadsTab extends ConsumerWidget {
  const _DownloadsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(downloadsListProvider);
    final completed = downloads.where((d) => d.isComplete).toList();
    final inProgress = downloads.where((d) => d.isDownloading).toList();

    if (downloads.isEmpty) {
      return const _EmptyState(
        icon: Icons.download_outlined,
        message: 'No downloads yet',
        hint: 'Tap the download icon on any song to save it offline',
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (inProgress.isNotEmpty) ...[
          _SectionHeader(title: 'Downloading (${inProgress.length})'),
          ...inProgress.map((d) => _DownloadTile(d: d, ref: ref)),
        ],
        if (completed.isNotEmpty) ...[
          _SectionHeader(title: 'Available Offline (${completed.length})'),
          ...completed.map((d) => _DownloadTile(d: d, ref: ref)),
        ],
      ],
    );
  }
}

class _DownloadTile extends StatelessWidget {
  final dynamic d;
  final WidgetRef ref;
  const _DownloadTile({required this.d, required this.ref});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: d.isComplete ? Colors.green.withOpacity(0.15) : Colors.grey.withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          d.isComplete ? Icons.download_done : Icons.downloading,
          color: d.isComplete ? Colors.green : Colors.grey,
        ),
      ),
      title: Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: d.isDownloading
          ? LinearProgressIndicator(value: d.progress / 100, minHeight: 3)
          : Text(
              d.isComplete
                  ? _fmtSize(d.fileSizeBytes)
                  : 'Interrupted',
              style: TextStyle(
                  fontSize: 12,
                  color: d.isComplete ? Colors.grey : Colors.red),
            ),
      trailing: d.isComplete
          ? IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => ref
                  .read(downloadsListProvider.notifier)
                  .removeDownload(d.trackId),
            )
          : null,
    );
  }

  String _fmtSize(int? bytes) {
    if (bytes == null || bytes == 0) return '';
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ── GENRES ───────────────────────────────────────────────────────────────────

class _GenresTab extends ConsumerWidget {
  const _GenresTab();

  static const _palette = [
    Colors.pink,     Colors.red,       Colors.orange,  Colors.purple,
    Colors.blue,     Colors.brown,     Colors.indigo,  Colors.green,
    Colors.teal,     Colors.cyan,      Colors.amber,   Colors.deepOrange,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genresAsync = ref.watch(genresProvider);
    return genresAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(
        message: 'Could not load genres',
        detail: e.toString(),
        onRetry: () => ref.invalidate(genresProvider),
      ),
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
            return _GenreCard(
                name: genre.label, color: color, imageUrl: genre.image);
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
  const _GenreCard(
      {required this.name, required this.color, this.imageUrl});

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
                  child: Image.network(imageUrl!,
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.music_note, color: color, size: 28)),
                )
              else
                Icon(Icons.music_note, color: color, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(name,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: color.withOpacity(0.9))),
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
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(title,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: Colors.grey)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String hint;
  const _EmptyState(
      {required this.icon, required this.message, required this.hint});

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
            Text(message,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(hint,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final String detail;
  final VoidCallback onRetry;
  const _ErrorState(
      {required this.message, required this.detail, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text(message,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(detail,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtBox extends StatelessWidget {
  final String? imageUrl;
  final IconData icon;
  const _ArtBox({this.imageUrl, required this.icon});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(imageUrl!,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallback()),
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
        child: Icon(icon, size: 22, color: Colors.grey),
      );
}
