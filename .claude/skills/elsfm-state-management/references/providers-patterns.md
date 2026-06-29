# Provider Patterns

Advanced patterns for complex state management.

## Computed Provider

Derive new state from existing providers.

```dart
final playlistsProvider = FutureProvider.autoDispose<List<Playlist>>((ref) async {
  return ref.read(playlistRepositoryProvider).getPlaylists();
});

// Computed: only Playlist with favorite tracks
final favoritePlaylistsProvider = FutureProvider.autoDispose<List<Playlist>>((ref) async {
  final playlists = await ref.watch(playlistsProvider.future);
  return playlists.where((p) => p.isFavorite).toList();
});

// Usage: automatically refetches when playlistsProvider changes
```

## Family Pattern (Parameterized)

```dart
final playlistProvider = FutureProvider.family<Playlist, int>((ref, id) async {
  return ref.read(playlistRepositoryProvider).getPlaylist(id);
});

// Usage
ref.watch(playlistProvider(123)); // Playlist with id 123
ref.watch(playlistProvider(456)); // Playlist with id 456
```

## Notifications (Listening)

Watch provider changes and perform side effects.

```dart
class PlaylistNotifier extends StateNotifier<PlaylistState> {
  PlaylistNotifier(this.ref) : super(const PlaylistState());

  final Ref ref;

  @override
  void initState() {
    // Listen when playlist changes
    ref.listen(playlistProvider, (previous, next) {
      if (next.playlist != previous?.playlist) {
        // Playlist changed, update UI or trigger action
        _syncPlaylistUI();
      }
    });

    // Listen to multiple providers
    ref.listen(
      userFavoritesProvider,
      (previous, next) {
        if (next.length != previous?.length) {
          // Favorites changed
          _updateFavoritesBadge();
        }
      },
    );
  }
}
```

## Chained Providers

Multiple levels of data transformation.

```dart
// Level 1: Raw API
final tracksProvider = FutureProvider.autoDispose<List<Track>>((ref) async {
  return ref.read(trackRepositoryProvider).getTracks(page: 1).then((r) => r.data);
});

// Level 2: Filter
final favoriteTracksProvider = FutureProvider.autoDispose<List<Track>>((ref) async {
  final tracks = await ref.watch(tracksProvider.future);
  final favorites = await ref.watch(userFavoritesProvider.future);
  return tracks.where((t) => favorites.contains(t.id)).toList();
});

// Level 3: Sort
final sortedFavoriteTracksProvider =
    FutureProvider.autoDispose<List<Track>>((ref) async {
  final tracks = await ref.watch(favoriteTracksProvider.future);
  return tracks..sort((a, b) => a.name.compareTo(b.name));
});

// Usage: watch final result
ref.watch(sortedFavoriteTracksProvider);
```

## Conditional Providers

Provider that depends on dynamic conditions.

```dart
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider.autoDispose<List<Track>>((ref) async {
  final query = ref.watch(searchQueryProvider);

  if (query.isEmpty) {
    return [];  // No search, return empty
  }

  return ref.read(searchRepositoryProvider).search(query).then((r) => r.data);
});

// Automatically refetches when searchQueryProvider changes
```

## Combining AsyncValue

Select specific states from multiple providers.

```dart
final trackProvider = FutureProvider.family<Track, int>((ref, id) async {
  return ref.read(trackRepositoryProvider).getTrack(id);
});

final albumProvider = FutureProvider.family<Album, int>((ref, id) async {
  return ref.read(albumRepositoryProvider).getAlbum(id);
});

// Combined state
final albumDetailsProvider = FutureProvider.autoDispose
    .family<AlbumDetails, int>((ref, albumId) async {
  final albumAsync = await ref.watch(albumProvider(albumId).future);
  final tracksAsync = await ref.watch(
    FutureProvider.autoDispose((ref) async {
      return ref.read(trackRepositoryProvider)
          .getAlbumTracks(albumId)
          .then((r) => r.data);
    }).future,
  );

  return AlbumDetails(album: albumAsync, tracks: tracksAsync);
});
```

## Select Pattern (Performance)

Only rebuild when specific part of state changes.

```dart
// Without select: rebuilds on ANY change to playerState
final player = ref.watch(playerProvider);

// With select: rebuilds ONLY when isPlaying changes
final isPlaying = ref.watch(
  playerProvider.select((state) => state.isPlaying),
);

// Multiple selects
final currentTrackName = ref.watch(
  playerProvider.select((state) => state.currentTrack?.name ?? 'Unknown'),
);

// Rebuild only if name differs (equality check)
```

## Manual Refresh

Explicit data refetch.

```dart
// Refresh single provider
ref.refresh(userProvider);

// Refresh all providers of type
ref.invalidateWhere((provider) {
  return provider is FutureProvider;
});

// Refresh with delay
Future.delayed(const Duration(seconds: 2), () {
  ref.refresh(userProvider);
});
```

## Testing with Mocks

Override providers in tests.

```dart
test('displays tracks when loaded', () async {
  final mockTracks = [
    Track(id: 1, name: 'Track 1', ...),
    Track(id: 2, name: 'Track 2', ...),
  ];

  final container = ProviderContainer(
    overrides: [
      trackRepositoryProvider.overrideWithValue(
        MockTrackRepository(mockTracks),
      ),
    ],
  );

  final tracks = await container.read(tracksProvider.future);
  expect(tracks, equals(mockTracks));
});
```
