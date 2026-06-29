# Performance Optimization

Preventing unnecessary rebuilds and optimizing memory.

## Select Pattern

Only watch specific properties to avoid rebuilds.

```dart
// ❌ AVOID: Rebuilds on ANY playerState change
final player = ref.watch(playerProvider);
// Rebuilds when: isPlaying, duration, position, error, anything changes

// ✅ GOOD: Rebuilds only when isPlaying changes
final isPlaying = ref.watch(
  playerProvider.select((state) => state.isPlaying),
);
// Rebuilds only when isPlaying value differs

// ✅ GOOD: Multiple selects
final currentTrackName = ref.watch(
  playerProvider.select((state) => state.currentTrack?.name ?? 'Unknown'),
);
final duration = ref.watch(
  playerProvider.select((state) => state.duration),
);
```

## Memoized Selects

For expensive computations.

```dart
final favoriteTracksProvider = FutureProvider.autoDispose<List<Track>>((ref) {
  // Don't recompute if input hasn't changed
  return ref.watch(tracksProvider.select((async) {
    return async.maybeWhen(
      data: (tracks) => tracks.where((t) => t.isFavorite).toList(),
      orElse: () => [],
    );
  })).future;
});
```

## AutoDispose Pattern

Auto-clean state when no longer watched.

```dart
// Default: cached forever (memory leak risk)
final tracksProvider = FutureProvider<List<Track>>((ref) async {
  return await fetchTracks();
});

// ✅ GOOD: Cleared when widget unmounts
final tracksProvider = FutureProvider.autoDispose<List<Track>>((ref) async {
  return await fetchTracks();
});

// Add to all FutureProviders by default
```

## Avoiding N+1 Queries

```dart
// ❌ BAD: Fetches each track individually
final trackDetailsProvider = FutureProvider.family<Track, int>((ref, id) async {
  return ref.read(trackRepositoryProvider).getTrack(id);
});

// Usage in list causes N queries
ListView.builder(
  itemCount: trackIds.length,
  itemBuilder: (context, index) {
    return ref.watch(trackDetailsProvider(trackIds[index]));
  },
);

// ✅ GOOD: Batch fetch, then select individual items
final allTracksProvider = FutureProvider.autoDispose<List<Track>>((ref) async {
  return (await ref.read(trackRepositoryProvider).getTracks()).data;
});

final trackProvider = FutureProvider.autoDispose
    .family<Track?, int>((ref, id) async {
  final allTracks = await ref.watch(allTracksProvider.future);
  return allTracks.firstWhereOrNull((t) => t.id == id);
});
```

## Caching Strategy

```dart
// Short-lived: user searches
final searchResultsProvider = FutureProvider.autoDispose<List<Track>>((ref) async {
  return await searchTracks(ref.watch(searchQueryProvider));
});

// Medium-lived: user playlists
final userPlaylistsProvider = FutureProvider<List<Playlist>>((ref) async {
  return await fetchUserPlaylists();
});

// Long-lived: static data (genres)
final genresProvider = FutureProvider<List<Genre>>((ref) async {
  return await fetchGenres();
});

// Don't use .autoDispose for static/long-lived data
// Use .autoDispose for dynamic/short-lived queries
```

## Memory Management

```dart
// Watch local-only state (not global)
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ GOOD: Local state, cleaned up on widget unmount
    final localState = ref.watch(
      StateProvider.autoDispose<String>((ref) => 'initial'),
    );

    // Use localState locally only
    return Text(localState);
  }
}

// For global state, use regular Provider
final globalConfigProvider = Provider<AppConfig>((ref) => AppConfig());
```

## Listener Pattern (Side Effects)

```dart
// DON'T use watch() in notification code
// Use listen() instead to avoid rebuilds
ref.listen(playerProvider, (previous, next) {
  if (next.isPlaying && previous?.isPlaying == false) {
    // Player started, show toast (not rebuild)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Playing: ${next.currentTrack?.name}')),
    );
  }
});

// This executes side effect without triggering widget rebuild
```

## Avoiding Rebuilds in Notifiers

```dart
// ❌ BAD: Unnecessary rebuild
class PlayerNotifier extends StateNotifier<PlayerState> {
  void _onPositionChanged(Duration position) {
    // Every millisecond!
    state = state.copyWith(position: position);
  }
}

// ✅ GOOD: Emit only meaningful changes
class PlayerNotifier extends StateNotifier<PlayerState> {
  void _onPositionChanged(Duration position) {
    // Only update if changed by at least 100ms
    if ((state.position.inMilliseconds - position.inMilliseconds).abs() > 100) {
      state = state.copyWith(position: position);
    }
  }
}
```

## Profiling

```dart
// Enable Riverpod logging
void main() {
  runApp(
    ProviderScope(
      observers: [DebugObserver()],  // Log all changes
      child: MyApp(),
    ),
  );
}

class DebugObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object newValue,
    ProviderContainer container,
  ) {
    print('[${provider.name ?? provider}] ${previousValue ?? '?'} -> $newValue');
  }
}

// Use DevTools Profiler to see rebuild counts
```

## Checklist

- [ ] Use .select() to watch specific properties only
- [ ] Use .autoDispose on all FutureProviders
- [ ] Batch-fetch instead of individual queries
- [ ] Use listen() for side effects, not watch()
- [ ] Clear large caches when not needed
- [ ] Profile with DebugObserver
- [ ] Test memory with Android Profiler
