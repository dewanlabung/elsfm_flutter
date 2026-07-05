import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elsfm/data/providers/http_client_provider.dart';
import 'package:elsfm/data/providers/api_client_provider.dart';
import 'package:elsfm/data/repositories/user_library_repository.dart';
import 'package:elsfm/features/auth/providers/auth_notifier.dart';
import '../services/library_service.dart';
import 'package:elsfm/data/models/track.dart';
import 'package:elsfm/data/models/album.dart';
import 'package:elsfm/data/models/artist.dart';
import 'package:elsfm/data/models/genre.dart';
import 'package:elsfm/data/models/playlist.dart';

/// Library repository provider — waits for Dio to be ready.
final libraryRepositoryProvider =
    FutureProvider<UserLibraryRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return UserLibraryRepository(dio: dio);
});

/// Library service provider — waits for the repository.
final libraryServiceProvider = FutureProvider<LibraryService>((ref) async {
  final repository = await ref.watch(libraryRepositoryProvider.future);
  return LibraryService(repository: repository);
});

/// Favorite toggle notifier (local UI state)
class FavoriteToggleNotifier extends StateNotifier<Map<int, bool>> {
  FavoriteToggleNotifier() : super({});
  void set(int trackId, bool isFavorited) {
    state = {...state, trackId: isFavorited};
  }
}

final favoriteToggleProvider =
    StateNotifierProvider<FavoriteToggleNotifier, Map<int, bool>>(
  (ref) => FavoriteToggleNotifier(),
);

/// User's liked tracks — GET /users/{userId}/liked-tracks
final likedTracksProvider = FutureProvider<List<Track>>((ref) async {
  final userId = ref.watch(authNotifierProvider).user?.id;
  if (userId == null) return [];
  final api = ref.watch(apiClientProvider);
  final result = await api.getLikedTracks(userId);
  return result.data;
});

/// User's liked albums — GET /users/{userId}/liked-albums
final likedAlbumsProvider = FutureProvider<List<Album>>((ref) async {
  final userId = ref.watch(authNotifierProvider).user?.id;
  if (userId == null) return [];
  final api = ref.watch(apiClientProvider);
  final result = await api.getLikedAlbums(userId);
  return result.data;
});

/// User's playlists — GET /users/{userId}/playlists
final userPlaylistsProvider = FutureProvider<List<Playlist>>((ref) async {
  final userId = ref.watch(authNotifierProvider).user?.id;
  if (userId == null) return [];
  final api = ref.watch(apiClientProvider);
  final result = await api.getUserPlaylists(userId);
  return result.data;
});

/// History — GET /users/{userId}/history
final playHistoryProvider = FutureProvider<List<Track>>((ref) async {
  final userId = ref.watch(authNotifierProvider).user?.id;
  if (userId == null) return [];
  try {
    final api = ref.watch(apiClientProvider);
    final result = await api.getHistory(userId, perPage: 50);
    return result.data;
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return [];
    rethrow;
  }
});

/// Followed artists — GET /users/{userId}/followed-artists
/// Returns empty list on 404 (endpoint optional in some BeMusic versions)
final followedArtistsProvider = FutureProvider<List<Artist>>((ref) async {
  final userId = ref.watch(authNotifierProvider).user?.id;
  if (userId == null) return [];
  try {
    final api = ref.watch(apiClientProvider);
    final result = await api.getFollowedArtists(userId);
    return result.data;
  } on DioException catch (e) {
    if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
      return [];
    }
    rethrow;
  }
});

/// Genres — GET /genres
final genresProvider = FutureProvider<List<Genre>>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.getGenres(perPage: 20);
});
