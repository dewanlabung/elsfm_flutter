import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elsfm/data/providers/http_client_provider.dart';
import 'package:elsfm/data/repositories/user_library_repository.dart';
import '../services/library_service.dart';
import 'package:elsfm/data/models/track.dart';

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
