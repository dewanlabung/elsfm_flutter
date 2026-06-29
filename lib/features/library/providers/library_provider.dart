import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elsfm/data/providers/http_client_provider.dart';
import 'package:elsfm/data/providers/api_client_provider.dart';
import 'package:elsfm/data/repositories/user_library_repository.dart';
import 'package:elsfm/features/auth/providers/auth_notifier.dart';
import '../services/library_service.dart';
import 'package:elsfm/data/models/track.dart';
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

/// Favorites provider
final favoritesProvider = FutureProvider<List<Track>>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  final user = authState.user;
  if (user == null) return [];

  final service = await ref.watch(libraryServiceProvider.future);
  return service.getFavorites(userId: user.id);
});

/// History provider
final historyProvider = FutureProvider<List<Track>>((ref) async {
  final service = await ref.watch(libraryServiceProvider.future);
  return service.getHistory();
});

/// Top tracks provider
final topTracksProvider =
    FutureProvider.family<List<Track>, String>((ref, period) async {
  final service = await ref.watch(libraryServiceProvider.future);
  return service.getTopTracks(period: period);
});

/// User playlists provider — loads playlists owned by the current user.
final userPlaylistsProvider = FutureProvider<List<Playlist>>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  final user = authState.user;
  if (user == null) return [];
  final api = await ref.watch(apiClientFutureProvider.future);
  final result = await api.getUserPlaylists(user.id, perPage: 50);
  return result.data;
});

/// Favorite toggle notifier
class FavoriteToggleNotifier extends StateNotifier<Map<int, bool>> {
  FavoriteToggleNotifier(super.state);

  void toggle(int trackId, bool isFavorited) {
    state = {...state, trackId: isFavorited};
  }
}

/// Favorite toggle provider
final favoriteToggleProvider =
    StateNotifierProvider<FavoriteToggleNotifier, Map<int, bool>>(
  (ref) => FavoriteToggleNotifier({}),
);
