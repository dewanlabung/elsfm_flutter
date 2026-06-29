import 'package:dio/dio.dart';
import '../models/playlist_v2.dart';
import '../models/app_error.dart';
import '../services/hive_service.dart';

/// Repository for playlist CRUD operations with Hive read-through cache.
class PlaylistRepository {
  final Dio dio;

  PlaylistRepository({required this.dio});

  /// Create a new playlist.
  Future<PlaylistV2> createPlaylist({
    required String name,
    String? description,
    bool isCollaborative = false,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/playlists',
        data: {
          'name': name,
          'description': description,
          'is_collaborative': isCollaborative,
        },
      );
      final playlist = PlaylistV2.fromJson(response.data!);
      // Invalidate the user playlist list cache on mutation.
      await HiveService.getPlaylistCache().invalidate('user_playlists');
      return playlist;
    } catch (e) {
      throw mapToAppError(e);
    }
  }

  /// Get all playlists for the current user.
  Future<List<PlaylistV2>> getUserPlaylists({
    int page = 1,
    int limit = 50,
  }) async {
    const cacheKey = 'user_playlists';
    final cache = HiveService.getPlaylistCache();

    final cachedList = cache.getList(cacheKey);
    if (cachedList != null) {
      return cachedList.map(PlaylistV2.fromJson).toList();
    }

    try {
      final response = await dio.get<dynamic>(
        '/playlists',
        queryParameters: {'page': page, 'limit': limit},
      );
      final items = ((response.data as List?) ?? [])
          .map((e) => PlaylistV2.fromJson(e as Map<String, dynamic>))
          .toList();
      await cache.putList(
        cacheKey,
        items.map((p) => p.toJson()).toList(),
      );
      return items;
    } catch (e) {
      throw mapToAppError(e);
    }
  }

  /// Get a specific playlist by ID.
  Future<PlaylistV2> getPlaylist(int playlistId) async {
    final cacheKey = 'playlist_$playlistId';
    final cache = HiveService.getPlaylistCache();

    final cached = cache.get(cacheKey);
    if (cached != null) {
      return PlaylistV2.fromJson(cached);
    }

    try {
      final response =
          await dio.get<Map<String, dynamic>>('/playlists/$playlistId');
      final playlist = PlaylistV2.fromJson(response.data!);
      await cache.put(cacheKey, response.data!);
      return playlist;
    } catch (e) {
      throw mapToAppError(e);
    }
  }

  /// Update playlist metadata.
  Future<PlaylistV2> updatePlaylist({
    required int playlistId,
    String? name,
    String? description,
    String? artwork,
    bool? isCollaborative,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (artwork != null) data['artwork'] = artwork;
      if (isCollaborative != null) data['is_collaborative'] = isCollaborative;

      final response = await dio.put<Map<String, dynamic>>(
        '/playlists/$playlistId',
        data: data,
      );
      final playlist = PlaylistV2.fromJson(response.data!);
      // Invalidate the individual and list caches after mutation.
      final cache = HiveService.getPlaylistCache();
      await cache.invalidate('playlist_$playlistId');
      await cache.invalidate('user_playlists');
      return playlist;
    } catch (e) {
      throw mapToAppError(e);
    }
  }

  /// Delete a playlist (soft delete — recoverable).
  Future<void> deletePlaylist(int playlistId) async {
    try {
      await dio.delete<void>('/playlists/$playlistId');
      final cache = HiveService.getPlaylistCache();
      await cache.invalidate('playlist_$playlistId');
      await cache.invalidate('user_playlists');
    } catch (e) {
      throw mapToAppError(e);
    }
  }

  /// Add a song to a playlist.
  Future<PlaylistV2> addSongToPlaylist({
    required int playlistId,
    required int trackId,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/playlists/$playlistId/songs',
        data: {'track_id': trackId},
      );
      final playlist = PlaylistV2.fromJson(response.data!);
      await HiveService.getPlaylistCache().invalidate('playlist_$playlistId');
      return playlist;
    } catch (e) {
      throw mapToAppError(e);
    }
  }

  /// Remove a song from a playlist.
  Future<PlaylistV2> removeSongFromPlaylist({
    required int playlistId,
    required int trackId,
  }) async {
    try {
      final response = await dio.delete<Map<String, dynamic>>(
        '/playlists/$playlistId/songs/$trackId',
      );
      final playlist = PlaylistV2.fromJson(response.data!);
      await HiveService.getPlaylistCache().invalidate('playlist_$playlistId');
      return playlist;
    } catch (e) {
      throw mapToAppError(e);
    }
  }

  /// Reorder a song in a playlist.
  Future<PlaylistV2> reorderSongInPlaylist({
    required int playlistId,
    required int trackId,
    required int newPosition,
  }) async {
    try {
      final response = await dio.patch<Map<String, dynamic>>(
        '/playlists/$playlistId/songs/$trackId',
        data: {'position': newPosition},
      );
      final playlist = PlaylistV2.fromJson(response.data!);
      await HiveService.getPlaylistCache().invalidate('playlist_$playlistId');
      return playlist;
    } catch (e) {
      throw mapToAppError(e);
    }
  }

  /// Bulk add songs to a playlist.
  Future<PlaylistV2> addSongsToPlaylist({
    required int playlistId,
    required List<int> trackIds,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/playlists/$playlistId/songs/bulk',
        data: {'track_ids': trackIds},
      );
      final playlist = PlaylistV2.fromJson(response.data!);
      await HiveService.getPlaylistCache().invalidate('playlist_$playlistId');
      return playlist;
    } catch (e) {
      throw mapToAppError(e);
    }
  }
}
