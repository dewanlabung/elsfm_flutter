# Riverpod Fundamentals

Core concepts of Riverpod state management.

## Basic Provider

Immutable value that Riverpod can cache and observe.

```dart
// Simple provider
final countProvider = Provider<int>((ref) => 42);

// Provider with dependency
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(dioProvider));
});

// Watch a provider
final value = ref.watch(countProvider); // 42
```

## StateProvider

Mutable state that can be changed.

```dart
final searchQueryProvider = StateProvider<String>((ref) => '');

// Update state
ref.read(searchQueryProvider.notifier).state = 'new query';

// Watch state
final query = ref.watch(searchQueryProvider);

// Reset to initial value
ref.invalidate(searchQueryProvider);
```

## FutureProvider

Async operation that caches result automatically.

```dart
final userProvider = FutureProvider<User>((ref) async {
  return ref.read(authServiceProvider).getCurrentUser();
});

// Caching: result is cached by default
// Invalidation: result cleared when dependencies change
// Auto-dispose: cleaned up when widget unmounts (with .autoDispose)

final userAutoDispose = FutureProvider.autoDispose<User>((ref) async {
  // Auto-invalidated when provider is no longer watched
  return ref.read(authServiceProvider).getCurrentUser();
});
```

### Using FutureProvider

```dart
final userAsync = ref.watch(userProvider);

userAsync.when(
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
  data: (user) => Text('Welcome ${user.name}'),
);

// Manually refresh
ref.refresh(userProvider);

// Watch specific part
final userName = ref.watch(
  userProvider.select((async) =>
    async.maybeWhen(data: (u) => u.name, orElse: () => 'Unknown')
  ),
);
```

## StreamProvider

Streaming data (continuous updates).

```dart
final playerPositionProvider = StreamProvider.autoDispose<Duration>((ref) {
  return ref.read(playerServiceProvider).positionStream;
});

// Use like FutureProvider
ref.watch(playerPositionProvider).when(
  data: (position) => Text('$position'),
  loading: () => CircularProgressIndicator(),
  error: (err, stack) => Text('Error'),
);
```

## StateNotifierProvider

Complex mutable state with methods.

```dart
class CountNotifier extends StateNotifier<int> {
  CountNotifier() : super(0);

  void increment() => state = state + 1;
  void decrement() => state = state - 1;
  void reset() => state = 0;
}

final countNotifierProvider = StateNotifierProvider<CountNotifier, int>((ref) {
  return CountNotifier();
});

// Watch state
final count = ref.watch(countNotifierProvider);

// Call methods
ref.read(countNotifierProvider.notifier).increment();
```

## Combining Providers

```dart
// Family: parameterized provider
final userProvider = FutureProvider.family<User, int>((ref, userId) async {
  return ref.read(userRepositoryProvider).getUser(userId);
});

// Usage
ref.watch(userProvider(123)); // Fetch user 123
ref.watch(userProvider(456)); // Fetch user 456

// Select: pick specific part of state
final isPlayingProvider = FutureProvider.autoDispose<bool>((ref) {
  return ref.watch(playerProvider.select((state) => state.isPlaying));
});
```

## Provider Lifecycle

```dart
// Default: cached forever
final cachedProvider = Provider<String>((ref) => 'value');

// Auto-dispose: cleared when not watched
final autoDisposeProvider = Provider.autoDispose<String>((ref) => 'value');

// Listen for invalidation
ref.listen(someProvider, (previous, next) {
  print('Provider changed: $previous -> $next');
});

// Manual invalidation
ref.invalidate(someProvider);
ref.invalidateWhere((provider) => provider is FutureProvider);
```

## Dependency Tracking

Riverpod automatically tracks dependencies.

```dart
final baseUrlProvider = Provider<String>((ref) => 'https://api.example.com');

final apiClientProvider = Provider<ApiClient>((ref) {
  final baseUrl = ref.watch(baseUrlProvider); // Dependency!
  return ApiClient(dio, baseUrl);
});

final tracksProvider = FutureProvider.autoDispose<List<Track>>((ref) {
  final apiClient = ref.watch(apiClientProvider); // Dependency!
  return apiClient.getTracks();
});

// If baseUrlProvider changes:
// - apiClientProvider is invalidated
// - tracksProvider is invalidated (refetches)
```

## Debugging

```dart
// Print provider value
debugPrint(ref.watch(someProvider).toString());

// Enable Riverpod logging
ProviderContainer(observers: [DebugObserver()]);

class DebugObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object newValue,
    ProviderContainer container,
  ) {
    print('$provider changed from $previousValue to $newValue');
  }
}
```
