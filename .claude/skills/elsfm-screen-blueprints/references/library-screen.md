# Library Screen

Tabbed library UI — Playlists, Songs, Artists, Albums. Mirrors
`lib/features/library/screens/library_screen.dart`.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:elsfm/features/auth/providers/auth_notifier.dart';
import 'package:elsfm/features/auth/models/auth_state.dart';
import 'package:elsfm/features/library/providers/library_provider.dart';
import 'package:elsfm/features/player/providers/player_notifier.dart';
import 'package:elsfm/features/player/widgets/track_context_menu.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Keep labels + icons together so the two lists never drift.
  static const _tabs = [
    (label: 'PLAYLISTS', icon: Icons.playlist_play),
    (label: 'SONGS',     icon: Icons.music_note),
    (label: 'ARTISTS',   icon: Icons.person),
    (label: 'ALBUMS',    icon: Icons.album),
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
  Widget build(BuildContext context, ) {
    final authState = ref.watch(authNotifierProvider);

    // Guard: unauthenticated users see a login prompt.
    if (authState.state != AuthState.authenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Library')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Log in to access your library'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.push('/login'),
                child: const Text('Log In'),
              ),
            ],
          ),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _PlaylistsTab(),
          _SongsTab(),
          _ArtistsTab(),
          _AlbumsTab(),
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

    return playlistsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(
        message: 'Could not load playlists',
        onRetry: () => ref.invalidate(userPlaylistsProvider),
      ),
      data: (playlists) => ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader(
            title: 'Your Playlists',
            action: IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'New playlist',
              onPressed: () => _showCreatePlaylistDialog(context, ref),
            ),
          ),
          if (playlists.isEmpty)
            const _EmptyState(
              icon: Icons.playlist_play,
              message: 'No playlists yet',
              hint: 'Tap + to create your first playlist',
            )
          else
            ...playlists.map(
              (p) => ListTile(
                leading: _ArtworkThumb(imageUrl: p.image),
                title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${p.views} plays'),
                onTap: () => context.push('/playlist/${p.id}'),
              ),
            ),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Playlist name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Wire to PlaylistService.createPlaylist() here.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Creating "${controller.text}"…')),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

// ── SONGS ────────────────────────────────────────────────────────────────────

class _SongsTab extends ConsumerWidget {
  const _SongsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(favoritesProvider);

    return tracksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(
        message: 'Could not load liked songs',
        onRetry: () => ref.invalidate(favoritesProvider),
      ),
      data: (tracks) {
        if (tracks.isEmpty) {
          return const _EmptyState(
            icon: Icons.favorite_border,
            message: 'No liked songs yet',
            hint: 'Heart a track to save it here',
          );
        }
        return ListView.builder(
          itemCount: tracks.length,
          itemBuilder: (context, i) {
            final track = tracks[i];
            return ListTile(
              leading: _ArtworkThumb(imageUrl: track.image),
              title: Text(track.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                track.artists.map((a) => a.name).join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => showTrackContextSheet(context, track),
              ),
              onTap: () =>
                  ref.read(playerProvider.notifier).setQueue(tracks, startIndex: i),
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
    // Swap the EmptyState for an AsyncValue.when() block once
    // a followedArtistsProvider is wired to the backend.
    return const _EmptyState(
      icon: Icons.person_outline,
      message: 'No followed artists',
      hint: 'Follow artists to see them here',
    );
  }
}

// ── ALBUMS ───────────────────────────────────────────────────────────────────

class _AlbumsTab extends ConsumerWidget {
  const _AlbumsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _EmptyState(
      icon: Icons.album_outlined,
      message: 'No saved albums',
      hint: 'Save albums to access them quickly',
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

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
            Text(message,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              hint,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(message, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtworkThumb extends StatelessWidget {
  final String? imageUrl;

  const _ArtworkThumb({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    Widget fallback = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.music_note, size: 22, color: Colors.grey),
    );

    if (imageUrl == null || imageUrl!.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        imageUrl!,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}
```

## Providers Referenced

| Provider | Source | Returns |
|----------|--------|---------|
| `authNotifierProvider` | `features/auth/providers/auth_notifier.dart` | `AuthStateData` |
| `userPlaylistsProvider` | `features/library/providers/library_provider.dart` | `AsyncValue<List<Playlist>>` |
| `favoritesProvider` | `features/library/providers/library_provider.dart` | `AsyncValue<List<Track>>` |
| `playerProvider` | `features/player/providers/player_notifier.dart` | `PlayerState` |

## GoRouter Entry

```dart
GoRoute(
  path: '/library',
  builder: (context, state) => const LibraryScreen(),
),
```

## Extending with Real Artists / Albums Tabs

```dart
// 1. Add a FutureProvider in library_provider.dart
final followedArtistsProvider = FutureProvider<List<Artist>>((ref) async {
  final service = ref.watch(libraryServiceProvider);
  return service.getFollowedArtists();
});

// 2. Replace EmptyState in _ArtistsTab.build() with AsyncValue.when()
final artistsAsync = ref.watch(followedArtistsProvider);
return artistsAsync.when(
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (e, _) => _ErrorState(message: 'Could not load artists', onRetry: ...),
  data: (artists) => GridView.builder(...),
);
```
