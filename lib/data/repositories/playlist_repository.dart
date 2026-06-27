import 'package:dio/dio.dart';
import '../models/playlist_v2.dart';

/// Repository for playlist CRUD operations
class PlaylistRepository {
  final Dio dio;

  PlaylistRepository({required this.dio});

  /// Create a new playlist
  /// Authorization: User must be authenticated
  Future<PlaylistV2> createPlaylist({
    required String name,
    String? description,
    bool isCollaborative = false,
  }) async {
    try {
      final response = await dio.post(
        '/api/v1/playlists',
        data: {
          'name': name,
          'description': description,
          'is_collaborative': isCollaborative,
        },
      );

      return PlaylistV2.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  /// Get all playlists for current user
  /// Authorization: User must be authenticated
  Future<List<PlaylistV2>> getUserPlaylists({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await dio.get(
        '/api/v1/playlists',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      return ((response.data as List?) ?? [])
          .map((e) => PlaylistV2.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      rethrow;
    }
  }

  /// Get a specific playlist by ID
  /// Authorization: User must have access (owner or shared)
  Future<PlaylistV2> getPlaylist(int playlistId) async {
    try {
      final response = await dio.get('/api/v1/playlists/$playlistId');
      return PlaylistV2.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  /// Update playlist metadata (name, description, artwork)
  /// Authorization: User must be owner
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

      final response = await dio.put(
        '/api/v1/playlists/$playlistId',
        data: data,
      );

      return PlaylistV2.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  /// Delete a playlist (soft delete - recoverable)
  /// Authorization: User must be owner
  Future<void> deletePlaylist(int playlistId) async {
    try {
      await dio.delete('/api/v1/playlists/$playlistId');
    } on DioException {
      rethrow;
    }
  }

  /// Add a song to a playlist
  /// Authorization: User must be owner/collaborator
  Future<PlaylistV2> addSongToPlaylist({
    required int playlistId,
    required int trackId,
  }) async {
    try {
      final response = await dio.post(
        '/api/v1/playlists/$playlistId/songs',
        data: {
          'track_id': trackId,
        },
      );

      return PlaylistV2.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  /// Remove a song from a playlist
  /// Authorization: User must be owner/collaborator
  Future<PlaylistV2> removeSongFromPlaylist({
    required int playlistId,
    required int trackId,
  }) async {
    try {
      final response = await dio.delete(
        '/api/v1/playlists/$playlistId/songs/$trackId',
      );

      return PlaylistV2.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  /// Reorder a song in a playlist
  /// Authorization: User must be owner/collaborator
  Future<PlaylistV2> reorderSongInPlaylist({
    required int playlistId,
    required int trackId,
    required int newPosition,
  }) async {
    try {
      final response = await dio.patch(
        '/api/v1/playlists/$playlistId/songs/$trackId',
        data: {
          'position': newPosition,
        },
      );

      return PlaylistV2.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  /// Bulk add songs to playlist
  /// Authorization: User must be owner/collaborator
  Future<PlaylistV2> addSongsToPlaylist({
    required int playlistId,
    required List<int> trackIds,
  }) async {
    try {
      final response = await dio.post(
        '/api/v1/playlists/$playlistId/songs/bulk',
        data: {
          'track_ids': trackIds,
        },
      );

      return PlaylistV2.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }
}
