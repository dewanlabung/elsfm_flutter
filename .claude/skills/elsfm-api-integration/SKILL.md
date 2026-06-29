---
name: elsfm-api-integration
description: |
  API layer patterns for integrating with the Laravel Bemusic backend. Covers API client
  configuration, model serialization (Track, Album, Playlist, User), repository patterns
  for data access, error handling with retries, and authentication flows. Use when adding
  new API endpoints, creating data models, or implementing backend integration.
---

# ELSFM API Integration

Consume the Laravel Bemusic backend API from the Flutter app with type-safe models, error handling, and retry logic.

## Quick Start

```dart
// Get API client from provider
final apiClient = ref.read(apiClientProvider);

// Fetch paginated tracks
final response = await apiClient.getTracks(page: 1, perPage: 20);
final tracks = response.data; // List<Track>
final totalPages = response.pagination?.totalPages;

// Log track play (analytics)
await apiClient.logTrackPlay(track.id);
```

## API Architecture

```
Data Layer
├── Services
│   ├── ApiClient (HTTP client with Dio)
│   └── AuthService (Login, token refresh, logout)
├── Models
│   ├── Track, Album, Artist, Playlist
│   ├── User, Lyric, Genre
│   └── BackendResponse, PaginationResponse
├── Repositories
│   ├── TrackRepository
│   ├── PlaylistRepository
│   ├── UserLibraryRepository
│   └── SearchRepository
└── Providers
    ├── apiClientProvider (Dio + interceptors)
    └── FutureProviders for each endpoint
```

## Core Concepts

### BaseUrl & Endpoints

```dart
class AppConfig {
  static const String apiBaseUrl = 'https://www.elsfm.com/api/v1';
  // Endpoints:
  // GET    /api/v1/tracks
  // GET    /api/v1/albums/{id}
  // POST   /api/v1/playlists
  // GET    /api/v1/search?q=query
}
```

See **[api-client-setup.md](references/api-client-setup.md)** for:
- Dio configuration
- Interceptors (auth headers, logging)
- Error handling
- Timeout and retry settings

### Models & Serialization

Dart models with `fromJson()` and `toJson()` factories for type-safe API responses.

```dart
// API returns JSON:
// {"id": 123, "name": "Track Name", "duration": 180000}

// Map to Dart model:
final track = Track.fromJson(json);
// track.duration is now Duration(milliseconds: 180000)
```

See **[models-serialization.md](references/models-serialization.md)** for:
- Model structure and patterns
- DateTime parsing
- Nullable fields
- Nested relationships

### Repositories

Encapsulate API calls and data transformations. Business logic depends on repository interface, not HTTP details.

```dart
abstract class TrackRepository {
  Future<Track> getTrack(int id);
  Future<PaginationResponse<Track>> getTracks({required int page});
  Future<void> logTrackPlay(int trackId);
}

// Implementation
class ApiTrackRepository implements TrackRepository {
  final ApiClient apiClient;

  ApiTrackRepository(this.apiClient);

  @override
  Future<Track> getTrack(int id) async {
    final response = await apiClient.getTrack(id);
    return response.data;
  }

  @override
  Future<PaginationResponse<Track>> getTracks({required int page}) =>
      apiClient.getTracks(page: page, perPage: 20);

  @override
  Future<void> logTrackPlay(int trackId) =>
      apiClient.logTrackPlay(trackId);
}
```

See **[repositories-pattern.md](references/repositories-pattern.md)** for:
- Repository interface design
- CRUD operations
- Data transformation
- Dependency injection

### Error Handling

Structured exception types with retry logic for transient failures.

```dart
try {
  final tracks = await trackRepository.getTracks(page: 1);
} on NetworkException catch (e) {
  print('Network error: ${e.message}');
  // Show retry button
} on ServerException catch (e) {
  print('Server error: ${e.statusCode}');
  // Show error message
} on UnauthorizedException catch (e) {
  // Trigger login flow
  ref.read(authNotifierProvider.notifier).logout();
}
```

See **[error-handling.md](references/error-handling.md)** for:
- Exception hierarchy
- Retry strategies
- Exponential backoff
- User-friendly error messages

### Authentication

Login, token management, and session restoration.

```dart
// Login with email/password
final user = await authService.login(
  email: 'user@example.com',
  password: 'password',
);

// Session token is stored securely and attached to all requests automatically

// Refresh token when expired
await authService.refreshToken();

// Logout clears stored credentials
await authService.logout();
```

See **[authentication-api.md](references/authentication-api.md)** for:
- Login/logout flows
- Token refresh
- Secure credential storage
- OAuth 2.0 integration

## Response Format

All API endpoints follow this envelope:

```json
{
  "data": {...},
  "pagination": {
    "total": 100,
    "per_page": 20,
    "current_page": 1,
    "last_page": 5
  },
  "message": "Success"
}
```

### Dart Wrapper
```dart
class BackendResponse<T> {
  final T data;
  final String? message;

  BackendResponse({required this.data, this.message});

  factory BackendResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    return BackendResponse(
      data: fromJsonT(json['data']),
      message: json['message'],
    );
  }
}

class PaginationResponse<T> extends BackendResponse<List<T>> {
  final PaginationMeta? pagination;

  PaginationResponse({
    required List<T> data,
    this.pagination,
  }) : super(data: data);
}
```

## Common Patterns

### Fetch & Cache (Riverpod)

```dart
final userTracksProvider = FutureProvider.autoDispose<List<Track>>((ref) async {
  final repository = ref.read(trackRepositoryProvider);
  return repository.getTracks(page: 1).then((response) => response.data);
});

// Usage: Data is cached and auto-refreshed
final tracks = await ref.read(userTracksProvider.future);

// Manual refresh
ref.refresh(userTracksProvider);
```

### Pagination

```dart
class PaginatedTracksNotifier extends StateNotifier<List<Track>> {
  PaginatedTracksNotifier(this.repository) : super([]);

  final TrackRepository repository;
  int _currentPage = 1;
  bool _hasMore = true;

  Future<void> loadMore() async {
    if (!_hasMore) return;

    final response = await repository.getTracks(page: _currentPage);
    state = [...state, ...response.data];

    _currentPage++;
    _hasMore = _currentPage <= (response.pagination?.totalPages ?? 1);
  }
}

final paginatedTracksProvider =
    StateNotifierProvider((ref) => PaginatedTracksNotifier(
          ref.watch(trackRepositoryProvider),
        ));
```

### Search with Debounce

```dart
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider.autoDispose<List<Track>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];

  final repository = ref.read(searchRepositoryProvider);
  return repository.searchTracks(query).then((response) => response.data);
});

// UI with debounce
TextField(
  onChanged: (value) {
    ref.read(searchQueryProvider.notifier).state = value;
  },
)
```

## Implementation Checklist

- [ ] ApiClient configured with base URL
- [ ] Dio interceptors added (auth headers, error handling)
- [ ] All model classes created with `fromJson()` / `toJson()`
- [ ] Repositories encapsulate API calls
- [ ] Error handling with structured exceptions
- [ ] Authentication flow (login, token refresh, logout)
- [ ] Providers (FutureProvider, StateNotifierProvider) for data
- [ ] Pagination implemented for list endpoints
- [ ] Caching strategy for frequently-accessed data
- [ ] Tests for repositories with mock ApiClient

## Reference Files

| File | Purpose |
|------|---------|
| [api-client-setup.md](references/api-client-setup.md) | Dio configuration, interceptors, base setup |
| [models-serialization.md](references/models-serialization.md) | Model creation patterns, fromJson/toJson |
| [repositories-pattern.md](references/repositories-pattern.md) | Repository interface & implementation |
| [error-handling.md](references/error-handling.md) | Exception types, retry logic, user feedback |
| [authentication-api.md](references/authentication-api.md) | Login, token management, OAuth |

## When to Reference This Skill

- **Adding new API endpoint** — create model, add to ApiClient, wrap in repository
- **Creating new data model** — use serialization patterns from models-serialization.md
- **Implementing authentication** — follow authentication-api.md
- **Handling API errors** — refer to error-handling.md for exception types
- **Setting up new repository** — follow pattern from repositories-pattern.md
- **Debugging API issues** — check api-client-setup.md for interceptor logging
