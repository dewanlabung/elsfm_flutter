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

/// Library repository provider
final libraryRepositoryProvider = Provider<UserLibraryRepository>((ref) {
  final dio = ref.watch(dioProvider).requireValue;
  return UserLibraryRepository(dio: dio);
});

/// Library service provider
final libraryServiceProvider = Provider<LibraryService>((ref) {
  final repository = ref.watch(libraryRepositoryProvider);
  return LibraryService(repository: repository);
});

/// Favorites provider
final favoritesProvider = FutureProvider<List<Track>>((ref) async {
  final service = ref.watch(libraryServiceProvider);
  return await service.getFavorites();
});

/// History provider
final historyProvider = FutureProvider<List<Track>>((ref) async {
  final service = ref.watch(libraryServiceProvider);
  return await service.getHistory();
});

/// Top tracks provider
final topTracksProvider = FutureProvider.family<List<Track>, String>((ref, period) async {
  final service = ref.watch(libraryServiceProvider);
  return await service.getTopTracks(period: period);
});

/// Favorite toggle notifier
class FavoriteToggleNotifier extends StateNotifier<Map<int, bool>> {
  FavoriteToggleNotifier(super.state);

  void toggle(int trackId, bool isFavorited) {
    state = {...state, trackId: isFavorited};
  }
}

/// Favorite toggle provider
final favoriteToggleProvider = StateNotifierProvider<FavoriteToggleNotifier, Map<int, bool>>(
  (ref) => FavoriteToggleNotifier({}),
);

/// User's liked tracks from API
final likedTracksProvider = FutureProvider<List<Track>>((ref) async {
  final userId = ref.watch(authNotifierProvider).user?.id;
  if (userId == null) return [];
  final api = ref.watch(apiClientProvider);
  final result = await api.getLikedTracks(userId);
  return result.data;
});

/// User's liked albums from API
final likedAlbumsProvider = FutureProvider<List<Album>>((ref) async {
  final userId = ref.watch(authNotifierProvider).user?.id;
  if (userId == null) return [];
  final api = ref.watch(apiClientProvider);
  final result = await api.getLikedAlbums(userId);
  return result.data;
});

/// User's own playlists from API
final userPlaylistsProvider = FutureProvider<List<Playlist>>((ref) async {
  final userId = ref.watch(authNotifierProvider).user?.id;
  if (userId == null) return [];
  final api = ref.watch(apiClientProvider);
  final result = await api.getUserPlaylists(userId);
  return result.data;
});

/// Genres from API
final genresProvider = FutureProvider<List<Genre>>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.getGenres(perPage: 20);
});

/// Followed artists from API
final followedArtistsProvider = FutureProvider<List<Artist>>((ref) async {
  final userId = ref.watch(authNotifierProvider).user?.id;
  if (userId == null) return [];
  final api = ref.watch(apiClientProvider);
  final result = await api.getFollowedArtists(userId);
  return result.data;
});
