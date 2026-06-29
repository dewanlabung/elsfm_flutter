import 'package:dio/dio.dart';
import '../models/playlist_v2.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import '../models/backend_response.dart';
import '../models/app_error.dart';
import '../services/hive_service.dart';

/// Repository for playlist CRUD operations with Hive read-through cache.
///
/// Implements all swagger playlist endpoints:
///   GET  /playlists/{id}
///   POST /playlists
///   PUT  /playlists/{id}
///   DELETE /playlists/{id}
///   GET  /playlists/{id}/tracks
///   POST /playlists/{id}/tracks/add
///   POST /playlists/{id}/tracks/remove
///   POST /playlists/{id}/follow
///   POST /playlists/{id}/unfollow
class PlaylistRepository {
  final Dio dio;

  PlaylistRepository({required this.dio});

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// POST /playlists — Create a new playlist.
  Future<PlaylistV2> createPlaylist({
    required String name,
    String? description,
    String? image,
    bool isPublic = false,
    bool isCollaborative = false,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/playlists',
        data: {
          'name': name,
          if (description != null) 'description': description,
          if (image != null) 'image': image,
          'public': isPublic,
          'collaborative': isCollaborative,
        },
      );
      final body = response.data!;
      final playlistJson =
          body['playlist'] as Map<String, dynamic>? ?? body;
      final playlist = PlaylistV2.fromJson(playlistJson);
      await HiveService.getPlaylistCache().invalidate('user_playlists');
      return playlist;
    } catch (e) {
      throw mapToAppError(e);
    }
  }

  /// GET /playlists/{id} — Get a specific playlist by ID.
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
      final body = response.data!;
      final playlistJson =
          body['playlist'] as Map<String, dynamic>? ?? body;
      final playlist = PlaylistV2.fromJson(playlistJson);
      await cache.put(cacheKey, playlistJson);
      return playlist;
    } catch (e) {
      throw mapToAppError(e);
    }
  }

  /// PUT /playlists/{id} — Update playlist metadata.
  Future<PlaylistV2> updatePlaylist({
    required int playlistId,
    String? name,
    String? description,
    String? image,
    bool? isPublic,
    bool? isCollaborative,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (image != null) data['image'] = image;
      if (isPublic != null) data['public'] = isPublic;
      if (isCollaborative != null) data['collaborative'] = isCollaborative;

      final response = await dio.put<Map<String, dynamic>>(
        '/playlists/$playlistId',
        data: data,
      );
      final body = response.data!;
      final playlistJson =
          body['playlist'] as Map<String, dynamic>? ?? body;
      final playlist = PlaylistV2.fromJson(playlistJson);
      final cache = HiveService.getPlaylistCache();
      await cache.invalidate('playlist_$playlistId');
      await cache.invalidate('user_playlists');
      return playlist;
    } catch (e) {
      throw mapToAppError(e);
    }
  }

  /// DELETE /playlists/{id} — Delete a playlist.
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

  // ---------------------------------------------------------------------------
  // Track management (swagger-correct paths)
  // ---------------------------------------------------------------------------

  /// GET /playlists/{id}/tracks — Paginated playlist tracks.
  Future<PaginationResponse<Track>> getPlaylistTracks(
    int playlistId, {
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/playlists/$playlistId/tracks',
        queryParameters: {'page': page, 'perPage': perPage},
      );
      final body = response.data!;
      final inner = body.containsKey('pagination')
          ? body['pagination'] as Map<String, dynamic>
          : body;
      final items = ((inner['data'] ?? []) as List)
          .map((e) => Track.fromJson(e as Map<String, dynamic>))
          .toList();
      return PaginationResponse(
        data: items,
        currentPage: (inner['current_page'] as num?)?.toInt() ?? 1,
        lastPage: (inner['last_page'] as num?)?.toInt() ?? 1,
        total: (inner['total'] as num?)?.toInt() ?? 0,
        perPage: (inner['per_page'] as num?)?.toInt() ?? perPage,
      );
    } catch (e) {
      throw mapToAppError(e);
    }
  }

  /// POST /playlists/{id}/tracks/add — Add one or more tracks.
  Future<Playlist> addTracksToPlaylist({
    required int playlistId,
    required List<int> trackIds,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/playlists/$playlistId/tracks/add',
        data: {'ids': trackIds},
      );
      final body = response.data!;
      final playlistJson =
          body['playlist'] as Map<String, dynamic>? ?? body;
      await HiveService.getPlaylistCache()
          .invalidate('playlist_$playlistId');
      return Playlist.fromJson(playlistJson);
    } catch (e) {
      throw mapToAppError(e);
    }
  }

  /// POST /playlists/{id}/tracks/remove — Remove one or more tracks.
  Future<Playlist> removeTracksFromPlaylist({
    required int playlistId,
    required List<int> trackIds,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/playlists/$playlistId/tracks/remove',
        data: {'ids': trackIds},
      );
      final body = response.data!;
      final playlistJson =
          body['playlist'] as Map<String, dynamic>? ?? body;
      await HiveService.getPlaylistCache()
          .invalidate('playlist_$playlistId');
      return Playlist.fromJson(playlistJson);
    } catch (e) {
      throw mapToAppError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Follow / unfollow
  // ---------------------------------------------------------------------------

  /// POST /playlists/{id}/follow
  Future<void> followPlaylist(int playlistId) async {
    try {
      await dio.post<void>('/playlists/$playlistId/follow');
      await HiveService.getPlaylistCache().invalidate('user_playlists');
    } catch (e) {
      throw mapToAppError(e);
    }
  }

  /// POST /playlists/{id}/unfollow
  Future<void> unfollowPlaylist(int playlistId) async {
    try {
      await dio.post<void>('/playlists/$playlistId/unfollow');
      await HiveService.getPlaylistCache().invalidate('user_playlists');
    } catch (e) {
      throw mapToAppError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Legacy helpers retained for callers that already use them
  // ---------------------------------------------------------------------------

  /// Get all playlists for the current user via the legacy /playlists list endpoint.
  /// Prefer [UserRepository.getUserPlaylists] which uses the swagger /users/me/playlists path.
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

  /// Add a single track (legacy helper — wraps [addTracksToPlaylist]).
  Future<Playlist> addSongToPlaylist({
    required int playlistId,
    required int trackId,
  }) =>
      addTracksToPlaylist(playlistId: playlistId, trackIds: [trackId]);

  /// Remove a single track (legacy helper — wraps [removeTracksFromPlaylist]).
  Future<Playlist> removeSongFromPlaylist({
    required int playlistId,
    required int trackId,
  }) =>
      removeTracksFromPlaylist(playlistId: playlistId, trackIds: [trackId]);
}
