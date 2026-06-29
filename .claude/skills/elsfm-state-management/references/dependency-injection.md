# Dependency Injection

Service injection via Riverpod providers.

## Service Providers

```dart
// Database service
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// API client
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(dioProvider));
});

// Repository
final trackRepositoryProvider = Provider<TrackRepository>((ref) {
  return ApiTrackRepository(ref.watch(apiClientProvider));
});

// State notifier
final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  return PlayerNotifier(ref.watch(playerServiceProvider));
});
```

## Using Injected Services

```dart
class MyNotifier extends StateNotifier<MyState> {
  final Ref ref;

  MyNotifier(this.ref) : super(const MyState());

  Future<void> fetchData() async {
    final repository = ref.read(trackRepositoryProvider);
    final tracks = await repository.getTracks(page: 1);
    state = state.copyWith(tracks: tracks.data);
  }
}

// Create provider
final myProvider = StateNotifierProvider<MyNotifier, MyState>((ref) {
  return MyNotifier(ref);
});
```

## Lazy Initialization

Services are only created when first accessed.

```dart
// DatabaseService created only when first read()
final databaseProvider = Provider<AppDatabase>((ref) {
  print('Creating database...'); // Prints only on first access
  return AppDatabase();
});

// First access: creates service
ref.read(databaseProvider);  // Output: "Creating database..."

// Subsequent accesses: reuse same instance
ref.read(databaseProvider);  // No output
ref.read(databaseProvider);  // No output
```

## Testing with Mocks

Override providers with mocks.

```dart
// Production provider
final trackRepositoryProvider = Provider<TrackRepository>((ref) {
  return ApiTrackRepository(ref.watch(apiClientProvider));
});

// Test with mock
test('loads tracks', () async {
  final container = ProviderContainer(
    overrides: [
      trackRepositoryProvider.overrideWithValue(
        MockTrackRepository(),
      ),
    ],
  );

  final tracks = await container.read(
    FutureProvider((ref) async {
      return ref.watch(trackRepositoryProvider).getTracks();
    }).future,
  );

  expect(tracks.data.length, greaterThan(0));
});
```

## Conditional Injection

```dart
final apiBaseUrlProvider = Provider<String>((ref) {
  return const String.fromEnvironment('API_URL', defaultValue: 'https://api.example.com');
});

final dioProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return Dio(BaseOptions(baseUrl: baseUrl));
});

// Override in tests
ProviderContainer(
  overrides: [
    apiBaseUrlProvider.overrideWithValue('http://localhost:8000'),
  ],
);
```

## Mock Repository Example

```dart
class MockTrackRepository implements TrackRepository {
  @override
  Future<PaginationResponse<Track>> getTracks({required int page}) async {
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate network
    return PaginationResponse(
      data: List.generate(
        20,
        (i) => Track(
          id: i,
          name: 'Mock Track $i',
          duration: const Duration(minutes: 3),
          src: '',
          artists: [],
          plays: 0,
        ),
      ),
      pagination: PaginationMeta(
        total: 100,
        perPage: 20,
        currentPage: page,
        lastPage: 5,
      ),
    );
  }

  @override
  Future<Track> getTrack(int id) async {
    return Track(
      id: id,
      name: 'Mock Track',
      duration: const Duration(minutes: 3),
      src: '',
      artists: [],
      plays: 0,
    );
  }

  @override
  Future<void> logTrackPlay(int trackId) async {}
}
```

## Provider Overrides

Multiple ways to override:

```dart
// Direct override
ProviderContainer(
  overrides: [
    trackRepositoryProvider.overrideWithValue(mockRepository),
  ],
);

// Lazy override (factory)
ProviderContainer(
  overrides: [
    trackRepositoryProvider.overrideWith((ref) {
      return MockTrackRepository();
    }),
  ],
);

// Family override
ProviderContainer(
  overrides: [
    userProvider.overrideWith((ref, id) async {
      return User(id: id, name: 'Mock User');
    }),
  ],
);
```

## Testing Full Flow

```dart
test('player loads and plays track', () async {
  final container = ProviderContainer(
    overrides: [
      trackRepositoryProvider.overrideWithValue(MockTrackRepository()),
      playerServiceProvider.overrideWithValue(MockPlayerService()),
    ],
  );

  // Get notifier
  final playerNotifier = container.read(playerProvider.notifier);

  // Test loading
  expect(playerNotifier.state.isLoading, false);

  // Load track
  await playerNotifier.loadTrack(1);

  // Verify state
  expect(playerNotifier.state.currentTrack?.name, 'Mock Track');
  expect(playerNotifier.state.isLoading, false);
});
```
