---
name: elsfm-state-management
description: |
  Riverpod state management patterns for the ELSFM Flutter app. Covers Provider fundamentals,
  StateNotifier for complex logic, FutureProvider for API calls, AsyncValue handling (loading/error/data),
  refresh patterns, dependency injection, and performance optimization. Use when creating new state,
  managing async operations, or integrating services across the app.
---

# ELSFM State Management

Riverpod patterns for managing player state, UI state, and API calls.

## Quick Start

```dart
// Simple state
final countProvider = StateProvider<int>((ref) => 0);

// API call (auto-caching)
final tracksProvider = FutureProvider.autoDispose<List<Track>>((ref) async {
  return ref.read(trackRepositoryProvider).getTracks(page: 1).then((r) => r.data);
});

// Complex state
final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  return PlayerNotifier(ref.read(playerServiceProvider));
});

// Usage in widget
final tracks = ref.watch(tracksProvider);
```

## Core Concepts

### Provider Types

| Type | Purpose | Example |
|------|---------|---------|
| `Provider` | Simple value | `apiClientProvider` |
| `StateProvider` | Mutable state | `searchQueryProvider` |
| `FutureProvider` | Async value (cached) | `userTracksProvider` |
| `StreamProvider` | Streaming data | `playerPositionStream` |
| `StateNotifierProvider` | Complex state + logic | `playerNotifierProvider` |

See **[riverpod-fundamentals.md](references/riverpod-fundamentals.md)** for:
- Provider creation and watching
- Auto-dispose behavior
- Caching strategies
- Invalidation and refresh

### Async Handling (AsyncValue)

```dart
final userProvider = FutureProvider<User>((ref) async { ... });

// In widget
@override
Widget build(BuildContext context, WidgetRef ref) {
  final userAsync = ref.watch(userProvider);

  return userAsync.when(
    loading: () => const LoadingScreen(),
    error: (error, stack) => ErrorScreen(error: error),
    data: (user) => UserScreen(user: user),
  );
}
```

See **[async-state.md](references/async-state.md)** for:
- AsyncValue.when() patterns
- Handling loading/error states
- Refresh and retry patterns

### StateNotifier

Complex state with methods for mutations.

```dart
class PlayerNotifier extends StateNotifier<PlayerState> {
  final PlayerService playerService;

  PlayerNotifier(this.playerService) : super(const PlayerState());

  Future<void> play() async {
    state = state.copyWith(isLoading: true);
    try {
      await playerService.play();
      state = state.copyWith(isPlaying: true, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

// Provider
final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  return PlayerNotifier(ref.read(playerServiceProvider));
});

// Usage
ref.read(playerProvider.notifier).play();
```

See **[providers-patterns.md](references/providers-patterns.md)** for:
- Computed providers
- Notifications and listening
- Combining state

### Dependency Injection

Services are provided via Riverpod and injected where needed.

```dart
// Define service providers
final playerServiceProvider = Provider<PlayerService>((ref) {
  return PlayerService();
});

final trackRepositoryProvider = Provider<TrackRepository>((ref) {
  return ApiTrackRepository(ref.read(apiClientProvider));
});

// Inject into StateNotifier
final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  return PlayerNotifier(ref.read(playerServiceProvider));
});

// Use everywhere without constructors
```

See **[dependency-injection.md](references/dependency-injection.md)** for:
- Service injection patterns
- Testing with mocks
- Overriding providers

## Common Patterns

### Fetch & Cache

```dart
final userLibraryProvider = FutureProvider.autoDispose<List<Track>>((ref) async {
  final response = await ref.read(trackRepositoryProvider).getTracks(page: 1);
  return response.data;
  // Auto-cached by Riverpod
  // Auto-invalidated on dispose
  // Refetch via: ref.refresh(userLibraryProvider)
});
```

### Search with Debounce

```dart
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider.autoDispose<List<Track>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  return ref.read(searchRepositoryProvider).search(query).then((r) => r.data);
  // Automatically refetches when searchQueryProvider changes
});

// UI
TextField(
  onChanged: (value) {
    ref.read(searchQueryProvider.notifier).state = value;
  },
)
```

### Paginated Lists

```dart
class PaginatedTracksNotifier extends StateNotifier<List<Track>> {
  int _currentPage = 1;
  bool _hasMore = true;

  Future<void> loadMore() async {
    if (!_hasMore) return;
    final response = await ref.read(trackRepositoryProvider).getTracks(page: _currentPage);
    state = [...state, ...response.data];
    _currentPage++;
    _hasMore = _currentPage <= (response.pagination?.totalPages ?? 1);
  }
}

final paginatedTracksProvider =
    StateNotifierProvider<PaginatedTracksNotifier, List<Track>>((ref) {
  return PaginatedTracksNotifier(ref);
});
```

### Listening to Changes

```dart
// In another notifier
final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  // Listen to player state changes
  ref.listen(playerNotifierProvider, (previous, next) {
    if (next.isPlaying && previous?.isPlaying == false) {
      // Started playing, log analytics
      analytics.logPlaybackStarted(next.currentTrack?.id);
    }
  });

  return PlayerNotifier(...);
});
```

## Performance Optimization

See **[performance.md](references/performance.md)** for:
- Preventing unnecessary rebuilds
- Select pattern for fine-grained updates
- Caching large data
- Memory management

```dart
// Watch only specific property
ref.watch(playerProvider.select((state) => state.isPlaying));

// Only rebuilds when isPlaying changes, not on other state updates
```

## Implementation Checklist

- [ ] Providers defined in `lib/data/providers/`
- [ ] StateNotifiers use immutable state (copyWith)
- [ ] FutureProviders for all async operations
- [ ] Error handling in providers
- [ ] Auto-dispose on unmount
- [ ] Dependency injection via Riverpod
- [ ] Performance optimized with select()
- [ ] Tests use mock providers
- [ ] No direct service instantiation in widgets
- [ ] Consistent naming (nameProvider)

## Reference Files

| File | Purpose |
|------|---------|
| [riverpod-fundamentals.md](references/riverpod-fundamentals.md) | Core concepts, watching, caching |
| [providers-patterns.md](references/providers-patterns.md) | Computed state, notifications |
| [async-state.md](references/async-state.md) | AsyncValue, error handling, refresh |
| [dependency-injection.md](references/dependency-injection.md) | Service injection, mocking, testing |
| [performance.md](references/performance.md) | Optimization, select pattern, memory |

## When to Reference This Skill

- **Creating new state** — use appropriate provider type
- **Handling API calls** — wrap with FutureProvider
- **Complex state logic** — implement StateNotifier
- **Injecting services** — use Riverpod providers
- **Performance issues** — optimize with select()
- **Testing** — override providers with mocks
- **Managing lifecycle** — use autoDispose for cleanup
