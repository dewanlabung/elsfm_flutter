# AsyncValue Handling

Managing loading, error, and data states.

## AsyncValue.when()

Three-way split for async state.

```dart
final tracksAsync = ref.watch(tracksProvider);

tracksAsync.when(
  loading: () => const LoadingScreen(),
  error: (error, stackTrace) => ErrorScreen(error: error),
  data: (tracks) => TrackList(tracks: tracks),
);
```

## AsyncValue Methods

```dart
final userAsync = ref.watch(userProvider);

// Check specific state
if (userAsync.isLoading) print('Loading...');
if (userAsync.isRefreshing) print('Refreshing...');
if (userAsync.hasError) print('Error!');

// Extract data or null
final user = userAsync.maybeWhen(
  data: (u) => u,
  orElse: () => null,
);

// Or return default
final userName = userAsync.whenData((user) => user.name);

// Map to UI model
final trackCards = tracksAsync.maybeWhen(
  data: (tracks) => tracks.map((t) => TrackCard(track: t)).toList(),
  orElse: () => [],
);
```

## Skip Loading on Refresh

Keep showing previous data while refreshing.

```dart
final tracksAsync = ref.watch(tracksProvider);

tracksAsync.when(
  loading: () => const LoadingScreen(),
  error: (err, st) => ErrorScreen(error: err),
  data: (tracks) => TrackList(tracks: tracks),
);

// While refreshing, `data` state is shown (not loading)
ref.refresh(tracksProvider);
```

## Manual Refresh

```dart
// Refresh and wait for result
await ref.refresh(userProvider.future);

// Refresh without waiting
ref.refresh(userProvider);

// Refresh and show loading state
final tracksAsync = ref.watch(tracksProvider);
if (!tracksAsync.isRefreshing) {
  ref.refresh(tracksProvider);
}
```

## Error Recovery

```dart
final tracksAsync = ref.watch(tracksProvider);

tracksAsync.when(
  error: (error, st) => Column(
    children: [
      ErrorWidget(error: error),
      SizedBox(height: 16),
      FilledButton(
        onPressed: () => ref.refresh(tracksProvider),
        child: const Text('Retry'),
      ),
    ],
  ),
  loading: () => LoadingWidget(),
  data: (tracks) => TrackList(tracks: tracks),
);
```

## Guard Data Before Use

```dart
final userAsync = ref.watch(userProvider);

// Unsafe: may throw if error
// final name = userAsync.maybeWhen(data: (u) => u.name, orElse: () => 'Unknown');

// Safe: explicit handling
final name = userAsync.maybeWhen(
  data: (user) {
    return user?.name ?? 'Unknown';  // null-safe
  },
  loading: () => 'Loading...',
  error: (_, __) => 'Error',
);
```

## Caching Old Data During Refresh

By default, FutureProvider keeps previous data while refetching.

```dart
final tracksProvider = FutureProvider.autoDispose<List<Track>>((ref) async {
  // This will refetch, but old data remains accessible
  return ref.read(trackRepositoryProvider).getTracks();
});

// Refresh without losing UI
ref.refresh(tracksProvider);  // Still shows old data until new data arrives

// Manual control if needed
AsyncValue<List<Track>> cachedData = ref.read(tracksProvider);
ref.refresh(tracksProvider);  // Refetch
// cachedData is still available from first read()
```

## Conditional Loading

```dart
class SearchScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);

    // Don't show loading if query is empty
    if (query.isEmpty) {
      return const Center(child: Text('Enter a search query'));
    }

    return resultsAsync.when(
      loading: () => const LoadingScreen(),
      error: (err, st) => ErrorScreen(error: err),
      data: (results) => ResultsList(results: results),
    );
  }
}
```

## FutureProvider vs FutureBuilder

```dart
// With Riverpod (preferred)
final dataProvider = FutureProvider.autoDispose<Data>((ref) async {
  return await fetchData();
});

// In widget
final async = ref.watch(dataProvider);
async.when(
  loading: () => Loading(),
  error: (e, st) => Error(),
  data: (data) => Content(data: data),
);

// FutureBuilder (avoid)
FutureBuilder<Data>(
  future: fetchData(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Loading();
    }
    if (snapshot.hasError) {
      return Error();
    }
    return Content(data: snapshot.data as Data);
  },
);
```

## Error Details

```dart
tracksAsync.whenData((tracks) {
  // Only called when data is available
  print('Loaded ${tracks.length} tracks');
});

tracksAsync.when(
  data: (tracks) {
    // Called with data
  },
  loading: () {
    // No data, loading
  },
  error: (DioException error, _) {
    // Access specific error type
    if (error.type == DioExceptionType.connectionTimeout) {
      return Text('Network timeout');
    }
    return Text('Error: ${error.message}');
  },
);
```
