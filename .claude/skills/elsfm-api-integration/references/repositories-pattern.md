# Repository Pattern

Encapsulate API calls and data access behind clean interfaces.

## Repository Interface

```dart
abstract class TrackRepository {
  Future<Track> getTrack(int id);
  Future<PaginationResponse<Track>> getTracks({
    required int page,
    int perPage = 20,
  });
  Future<void> logTrackPlay(int trackId);
}

abstract class PlaylistRepository {
  Future<Playlist> getPlaylist(int id);
  Future<PaginationResponse<Playlist>> getPlaylists({required int page});
  Future<Playlist> createPlaylist(String name);
  Future<void> updatePlaylist(int id, String name);
  Future<void> deletePlaylist(int id);
  Future<void> addTrackToPlaylist(int playlistId, int trackId);
  Future<void> removeTrackFromPlaylist(int playlistId, int trackId);
}
```

## Implementation

```dart
class ApiTrackRepository implements TrackRepository {
  final ApiClient apiClient;

  ApiTrackRepository(this.apiClient);

  @override
  Future<Track> getTrack(int id) async {
    final response = await apiClient.getTrack(id);
    return response.data;
  }

  @override
  Future<PaginationResponse<Track>> getTracks({
    required int page,
    int perPage = 20,
  }) =>
      apiClient.getTracks(page: page, perPage: perPage);

  @override
  Future<void> logTrackPlay(int trackId) =>
      apiClient.logTrackPlay(trackId);
}

class ApiPlaylistRepository implements PlaylistRepository {
  final ApiClient apiClient;

  ApiPlaylistRepository(this.apiClient);

  @override
  Future<Playlist> getPlaylist(int id) async {
    final response = await apiClient.getPlaylist(id);
    return response.data;
  }

  @override
  Future<PaginationResponse<Playlist>> getPlaylists({required int page}) =>
      apiClient.getPlaylists(page: page);

  @override
  Future<Playlist> createPlaylist(String name) async {
    final response = await apiClient.createPlaylist(name);
    return response.data;
  }

  @override
  Future<void> updatePlaylist(int id, String name) =>
      apiClient.updatePlaylist(id, name);

  @override
  Future<void> deletePlaylist(int id) =>
      apiClient.deletePlaylist(id);

  @override
  Future<void> addTrackToPlaylist(int playlistId, int trackId) =>
      apiClient.addTrackToPlaylist(playlistId, trackId);

  @override
  Future<void> removeTrackFromPlaylist(int playlistId, int trackId) =>
      apiClient.removeTrackFromPlaylist(playlistId, trackId);
}
```

## Riverpod Providers

```dart
final trackRepositoryProvider = Provider<TrackRepository>((ref) {
  return ApiTrackRepository(ref.read(apiClientProvider));
});

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  return ApiPlaylistRepository(ref.read(apiClientProvider));
});

// Use in other providers
final userTracksProvider = FutureProvider.autoDispose<List<Track>>((ref) async {
  final repository = ref.read(trackRepositoryProvider);
  final response = await repository.getTracks(page: 1);
  return response.data;
});

final playlistProvider = FutureProvider.autoDispose
    .family<Playlist, int>((ref, playlistId) async {
  final repository = ref.read(playlistRepositoryProvider);
  return repository.getPlaylist(playlistId);
});
```

## Data Transformation

Repositories can transform API responses before returning to UI.

```dart
class TrackWithMetadata {
  final Track track;
  final bool isFavorite;
  final bool isDownloaded;

  TrackWithMetadata({
    required this.track,
    required this.isFavorite,
    required this.isDownloaded,
  });
}

class EnrichedTrackRepository implements TrackRepository {
  final TrackRepository _apiRepository;
  final FavoritesService _favoritesService;
  final DownloadService _downloadService;

  EnrichedTrackRepository(
    this._apiRepository,
    this._favoritesService,
    this._downloadService,
  );

  @override
  Future<Track> getTrack(int id) => _apiRepository.getTrack(id);

  Future<TrackWithMetadata> getTrackWithMetadata(int id) async {
    final track = await _apiRepository.getTrack(id);
    final isFavorite = await _favoritesService.isFavorite(id);
    final isDownloaded = await _downloadService.isDownloaded(id);

    return TrackWithMetadata(
      track: track,
      isFavorite: isFavorite,
      isDownloaded: isDownloaded,
    );
  }

  // Other methods delegate to _apiRepository
  @override
  Future<PaginationResponse<Track>> getTracks({required int page, int perPage = 20}) =>
      _apiRepository.getTracks(page: page, perPage: perPage);

  @override
  Future<void> logTrackPlay(int trackId) =>
      _apiRepository.logTrackPlay(trackId);
}
```

## Caching Repository

Add caching layer on top of API repository.

```dart
class CachedTrackRepository implements TrackRepository {
  final TrackRepository _apiRepository;
  final CacheService _cacheService;
  static const cacheDuration = Duration(hours: 1);

  CachedTrackRepository(this._apiRepository, this._cacheService);

  @override
  Future<Track> getTrack(int id) async {
    // Check cache first
    final cached = await _cacheService.get('track_$id');
    if (cached != null) return cached as Track;

    // Fetch from API
    final track = await _apiRepository.getTrack(id);

    // Store in cache
    await _cacheService.set('track_$id', track, cacheDuration);

    return track;
  }

  @override
  Future<PaginationResponse<Track>> getTracks({required int page, int perPage = 20}) {
    // Don't cache paginated lists (they change frequently)
    return _apiRepository.getTracks(page: page, perPage: perPage);
  }

  @override
  Future<void> logTrackPlay(int trackId) =>
      _apiRepository.logTrackPlay(trackId);
}
```

## Mock Repository for Testing

```dart
class MockTrackRepository implements TrackRepository {
  @override
  Future<Track> getTrack(int id) async {
    return Track(
      id: id,
      name: 'Test Track',
      duration: const Duration(minutes: 3),
      src: 'https://example.com/track.mp3',
      artists: [],
      plays: 0,
    );
  }

  @override
  Future<PaginationResponse<Track>> getTracks({required int page, int perPage = 20}) async {
    return PaginationResponse(
      data: List.generate(perPage, (i) =>
        Track(
          id: (page - 1) * perPage + i,
          name: 'Track ${i + 1}',
          duration: const Duration(minutes: 3),
          src: 'https://example.com/track.mp3',
          artists: [],
          plays: 0,
        ),
      ),
      pagination: PaginationMeta(
        total: 100,
        perPage: perPage,
        currentPage: page,
        lastPage: (100 / perPage).ceil(),
      ),
    );
  }

  @override
  Future<void> logTrackPlay(int trackId) async {}
}

// Usage in tests
test('getTracks returns paginated response', () async {
  final repository = MockTrackRepository();
  final response = await repository.getTracks(page: 1);

  expect(response.data.length, 20);
  expect(response.pagination?.currentPage, 1);
});
```
