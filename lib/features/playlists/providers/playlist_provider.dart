import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elsfm/data/providers/http_client_provider.dart';
import 'package:elsfm/data/repositories/playlist_repository.dart';
import '../services/playlist_service.dart';
import 'package:elsfm/data/models/playlist_v2.dart';

/// Playlist repository provider
final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  final dio = ref.watch(httpClientProvider);
  return PlaylistRepository(dio: dio);
});

/// Playlist service provider
final playlistServiceProvider = Provider<PlaylistService>((ref) {
  final repository = ref.watch(playlistRepositoryProvider);
  return PlaylistService(repository: repository);
});

/// User playlists list provider
final userPlaylistsProvider = FutureProvider<List<PlaylistV2>>((ref) async {
  final service = ref.watch(playlistServiceProvider);
  return await service.getUserPlaylists();
});

/// Single playlist provider
final playlistProvider = FutureProvider.family<PlaylistV2, int>((ref, playlistId) async {
  final service = ref.watch(playlistServiceProvider);
  return await service.getPlaylist(playlistId);
});

/// Create playlist notifier
class CreatePlaylistNotifier extends AsyncNotifier<PlaylistV2?> {
  @override
  Future<PlaylistV2?> build() async {
    return null;
  }

  Future<void> create({required String name, String? description}) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(playlistServiceProvider);
      final playlist = await service.createPlaylist(
        name: name,
        description: description,
      );
      
      // Invalidate user playlists to refresh
      ref.invalidate(userPlaylistsProvider);
      
      state = AsyncValue.data(playlist);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

/// Create playlist provider
final createPlaylistProvider = AsyncNotifierProvider<CreatePlaylistNotifier, PlaylistV2?>(
  () => CreatePlaylistNotifier(),
);

/// Update playlist notifier
class UpdatePlaylistNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    return false;
  }

  Future<void> update({
    required int playlistId,
    String? name,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(playlistServiceProvider);
      await service.updatePlaylist(
        playlistId: playlistId,
        name: name,
        description: description,
      );
      
      // Invalidate playlists
      ref.invalidate(playlistProvider(playlistId));
      ref.invalidate(userPlaylistsProvider);
      
      state = const AsyncValue.data(true);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

/// Update playlist provider
final updatePlaylistProvider = AsyncNotifierProvider<UpdatePlaylistNotifier, bool>(
  () => UpdatePlaylistNotifier(),
);

/// Delete playlist notifier
class DeletePlaylistNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    return false;
  }

  Future<void> delete(int playlistId) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(playlistServiceProvider);
      await service.deletePlaylist(playlistId);
      
      // Invalidate playlists
      ref.invalidate(userPlaylistsProvider);
      
      state = const AsyncValue.data(true);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

/// Delete playlist provider
final deletePlaylistProvider = AsyncNotifierProvider<DeletePlaylistNotifier, bool>(
  () => DeletePlaylistNotifier(),
);
