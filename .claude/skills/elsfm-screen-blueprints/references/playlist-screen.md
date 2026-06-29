# Playlist Screen

Full-featured playlist view with add/remove tracks and CRUD dialogs. Mirrors the
pattern from `lib/features/playlist/screens/playlist_detail_screen.dart` and the
`PlaylistService` / `PlaylistRepository` pair.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elsfm/data/models/track.dart';
import 'package:elsfm/data/providers/api_client_provider.dart';
import 'package:elsfm/features/player/providers/player_notifier.dart';
import 'package:elsfm/features/player/widgets/track_context_menu.dart';
import 'package:elsfm/features/playlists/services/playlist_service.dart';
import 'package:elsfm/data/repositories/playlist_repository.dart';
import 'package:elsfm/data/providers/http_client_provider.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final _playlistServiceProvider = Provider<PlaylistService>((ref) {
  final dio = ref.watch(dioProvider).requireValue;
  return PlaylistService(repository: PlaylistRepository(dio: dio));
});

// FutureProvider.family so each playlist ID gets its own cached slot.
final playlistDetailProvider =
    FutureProvider.family<_PlaylistDetail, int>((ref, id) async {
  final api = ref.watch(apiClientProvider);
  final raw = await api.getPlaylist(id);
  final data = raw['playlist'] as Map<String, dynamic>? ?? raw;
  final tracksRaw = ((data['tracks']?['data'] ?? []) as List);
  final tracks =
      tracksRaw.map((e) => Track.fromJson(e as Map<String, dynamic>)).toList();
  final image = data['image'] as String?;
  return _PlaylistDetail(
    name: data['name'] as String? ?? '',
    description: data['description'] as String?,
    image: (image != null && image.isNotEmpty && !image.startsWith('http'))
        ? 'https://www.elsfm.com/$image'
        : image,
    tracks: tracks,
  );
});

class _PlaylistDetail {
  final String name;
  final String? description;
  final String? image;
  final List<Track> tracks;

  const _PlaylistDetail({
    required this.name,
    this.description,
    this.image,
    required this.tracks,
  });
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class PlaylistScreen extends ConsumerWidget {
  final int playlistId;

  const PlaylistScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(playlistDetailProvider(playlistId));

    return Scaffold(
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorBody(
          message: err.toString(),
          onRetry: () => ref.invalidate(playlistDetailProvider(playlistId)),
        ),
        data: (detail) => _PlaylistBody(
          playlistId: playlistId,
          detail: detail,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _PlaylistBody extends ConsumerWidget {
  final int playlistId;
  final _PlaylistDetail detail;

  const _PlaylistBody({required this.playlistId, required this.detail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        // ── Hero header ────────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Rename playlist',
              onPressed: () => _showRenameDialog(context, ref, detail.name),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete playlist',
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              detail.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                detail.image != null
                    ? Image.network(
                        detail.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _artworkFallback(context),
                      )
                    : _artworkFallback(context),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Track count + Play All ─────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${detail.tracks.length} tracks',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                ),
                if (detail.tracks.isNotEmpty)
                  FilledButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play All'),
                    onPressed: () => ref
                        .read(playerProvider.notifier)
                        .setQueue(detail.tracks, startIndex: 0),
                  ),
              ],
            ),
          ),
        ),

        // ── Optional description ───────────────────────────────────────────
        if (detail.description != null && detail.description!.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                detail.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
              ),
            ),
          ),

        // ── Track list ────────────────────────────────────────────────────
        detail.tracks.isEmpty
            ? const SliverFillRemaining(
                child: Center(
                  child: Text('No tracks yet — add some!'),
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _TrackRow(
                    playlistId: playlistId,
                    track: detail.tracks[i],
                    index: i,
                    allTracks: detail.tracks,
                  ),
                  childCount: detail.tracks.length,
                ),
              ),

        // Bottom spacing so the mini-player doesn't overlap the last item.
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _artworkFallback(BuildContext context) => Container(
        color: Theme.of(context).colorScheme.surfaceVariant,
        child: const Icon(Icons.playlist_play, size: 80, color: Colors.grey),
      );

  void _showRenameDialog(BuildContext context, WidgetRef ref, String current) {
    final controller = TextEditingController(text: current);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Playlist name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final service = ref.read(_playlistServiceProvider);
                await service.updatePlaylist(
                  playlistId: playlistId,
                  name: controller.text.trim(),
                );
                ref.invalidate(playlistDetailProvider(playlistId));
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Rename failed: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete playlist?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final service = ref.read(_playlistServiceProvider);
                await service.deletePlaylist(playlistId);
                if (context.mounted) Navigator.of(context).pop();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Delete failed: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Track Row
// ---------------------------------------------------------------------------

class _TrackRow extends ConsumerWidget {
  final int playlistId;
  final Track track;
  final int index;
  final List<Track> allTracks;

  const _TrackRow({
    required this.playlistId,
    required this.track,
    required this.index,
    required this.allTracks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 44,
          height: 44,
          child: track.image != null
              ? Image.network(
                  track.image!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imgFallback(context),
                )
              : _imgFallback(context),
        ),
      ),
      title: Text(track.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        track.artists.map((a) => a.name).join(', '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _fmt(track.duration),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
          ),
          // Remove from playlist
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            tooltip: 'Remove from playlist',
            onPressed: () => _removeTrack(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 20),
            onPressed: () => showTrackContextSheet(context, track),
          ),
        ],
      ),
      onTap: () => ref
          .read(playerProvider.notifier)
          .setQueue(allTracks, startIndex: index),
    );
  }

  Widget _imgFallback(BuildContext context) => Container(
        color: Theme.of(context).colorScheme.surfaceVariant,
        child: const Icon(Icons.music_note, size: 20),
      );

  String _fmt(Duration d) {
    final m = d.inSeconds ~/ 60;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _removeTrack(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(_playlistServiceProvider);
      await service.removeSong(playlistId: playlistId, trackId: track.id);
      ref.invalidate(playlistDetailProvider(playlistId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not remove track: $e')),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Error body
// ---------------------------------------------------------------------------

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

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
            Text('Failed to load playlist',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
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
```

## Providers Referenced

| Provider | Returns |
|----------|---------|
| `playlistDetailProvider(id)` | `AsyncValue<_PlaylistDetail>` |
| `_playlistServiceProvider` | `PlaylistService` |
| `playerProvider` | `PlayerState` |
| `apiClientProvider` | `ApiClient` |
| `dioProvider` | `AsyncValue<Dio>` |

## GoRouter Entry

```dart
GoRoute(
  path: '/playlist/:id',
  builder: (context, state) {
    final id = int.parse(state.pathParameters['id'] ?? '0');
    return PlaylistScreen(playlistId: id);
  },
),
```

## PlaylistService CRUD Reference

```dart
// Create
await service.createPlaylist(name: 'My Mix');

// Rename
await service.updatePlaylist(playlistId: id, name: 'New Name');

// Delete
await service.deletePlaylist(id);

// Add track
await service.addSong(playlistId: id, trackId: track.id);

// Remove track
await service.removeSong(playlistId: id, trackId: track.id);

// Reorder
await service.reorderSong(playlistId: id, trackId: track.id, newPosition: 2);
```

Always call `ref.invalidate(playlistDetailProvider(id))` after any mutation to
refresh the UI from the source of truth.
