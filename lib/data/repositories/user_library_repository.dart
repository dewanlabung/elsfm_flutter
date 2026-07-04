import 'package:dio/dio.dart';
import '../models/user_library.dart';
import '../models/track.dart';

/// Repository for user library (favorites, history, etc.)
class UserLibraryRepository {
  final Dio dio;

  UserLibraryRepository({required this.dio});

  /// Get user's complete library (favorites, history, statistics)
  /// Authorization: User must be authenticated
  /// Endpoint: GET /api/v1/user/library
  Future<UserLibrary> getUserLibrary() async {
    try {
      final response = await dio.get('/user/library');
      return UserLibrary.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  /// Get user's favorite songs
  /// Authorization: User must be authenticated
  /// Endpoint: GET /api/v1/users/{userId}/liked-tracks
  Future<List<Track>> getFavorites({
    int? userId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      // BeMusic typically uses /users/{id}/liked-tracks
      final path = userId != null ? '/users/$userId/liked-tracks' : '/users/me/liked-tracks';
      
      final response = await dio.get(
        path,
        queryParameters: {
          'page': page,
          'per_page': limit,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        // Handle BeMusic pagination wrapper
        final list = (data['pagination']?['data'] ?? data['data']) as List?;
        if (list != null) {
          return list
              .map((e) => Track.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      if (data is List) {
        return data
            .map((e) => Track.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException {
      rethrow;
    }
  }

  /// Add a song to favorites
  /// Authorization: User must be authenticated
  /// Endpoint: POST /api/v1/users/me/add-to-library
  Future<void> addFavorite(int trackId) async {
    try {
      await dio.post(
        '/users/me/add-to-library',
        data: {
          'likeables': [
            {'likeable_id': trackId, 'likeable_type': 'track'}
          ],
        },
      );
    } on DioException {
      rethrow;
    }
  }

  /// Remove a song from favorites
  /// Authorization: User must be authenticated
  /// Endpoint: POST /api/v1/users/me/remove-from-library
  Future<void> removeFavorite(int trackId) async {
    try {
      await dio.post(
        '/users/me/remove-from-library',
        data: {
          'likeables': [
            {'likeable_id': trackId, 'likeable_type': 'track'}
          ],
        },
      );
    } on DioException {
      rethrow;
    }
  }

  /// Follow an artist
  Future<void> followArtist(int artistId) async {
    try {
      await dio.post('/users/me/add-to-library', data: {
        'likeables': [{'likeable_id': artistId, 'likeable_type': 'artist'}],
      });
    } on DioException { rethrow; }
  }

  /// Unfollow an artist
  Future<void> unfollowArtist(int artistId) async {
    try {
      await dio.post('/users/me/remove-from-library', data: {
        'likeables': [{'likeable_id': artistId, 'likeable_type': 'artist'}],
      });
    } on DioException { rethrow; }
  }

  /// Like an album
  Future<void> likeAlbum(int albumId) async {
    try {
      await dio.post('/users/me/add-to-library', data: {
        'likeables': [{'likeable_id': albumId, 'likeable_type': 'album'}],
      });
    } on DioException { rethrow; }
  }

  /// Unlike an album
  Future<void> unlikeAlbum(int albumId) async {
    try {
      await dio.post('/users/me/remove-from-library', data: {
        'likeables': [{'likeable_id': albumId, 'likeable_type': 'album'}],
      });
    } on DioException { rethrow; }
  }

  /// Check if a song is favorited
  /// Authorization: User must be authenticated
  /// Endpoint: GET /api/v1/user/library/tracks/{trackId}/is-favorite
  Future<bool> isFavorited(int trackId) async {
    try {
      final response = await dio.get(
        '/user/library/tracks/$trackId/is-favorite',
      );

      return response.data?['is_favorited'] as bool? ?? false;
    } on DioException {
      rethrow;
    }
  }

  /// Get user's play history
  /// Authorization: User must be authenticated
  /// Endpoint: GET /api/v1/user/history
  Future<List<Track>> getHistory({
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final response = await dio.get(
        '/user/history',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      // Handle paginated response format
      final data = response.data;
      if (data is List) {
        return data
            .map((e) => Track.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (data is Map<String, dynamic>) {
        final tracks = (data['data'] as List?) ?? [];
        return tracks
            .map((e) => Track.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException {
      rethrow;
    }
  }

  /// Log a song play (record listening history)
  /// Authorization: User must be authenticated
  /// Endpoint: POST /api/v1/user/history
  Future<void> logPlay({
    required int trackId,
    int? durationPlayedSeconds,
  }) async {
    try {
      await dio.post(
        '/user/history',
        data: {
          'track_id': trackId,
          if (durationPlayedSeconds != null) 'duration_played_seconds': durationPlayedSeconds,
        },
      );
    } on DioException {
      rethrow;
    }
  }

  /// Clear user's play history
  /// Authorization: User must be authenticated
  /// Endpoint: DELETE /api/v1/user/history
  Future<void> clearHistory() async {
    try {
      await dio.delete('/user/history');
    } on DioException {
      rethrow;
    }
  }

  /// Get listening statistics for user
  /// Authorization: User must be authenticated
  /// Endpoint: GET /api/v1/user/statistics
  Future<Map<String, dynamic>> getStatistics({
    String period = 'month', // 'week', 'month', 'year', 'all'
  }) async {
    try {
      final response = await dio.get(
        '/user/statistics',
        queryParameters: {
          'period': period,
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException {
      rethrow;
    }
  }

  /// Get top tracks for user in a time period
  /// Authorization: User must be authenticated
  /// Endpoint: GET /api/v1/user/top-tracks
  Future<List<Track>> getTopTracks({
    String period = 'month',
    int limit = 20,
  }) async {
    try {
      final response = await dio.get(
        '/user/top-tracks',
        queryParameters: {
          'period': period,
          'limit': limit,
        },
      );

      // Handle paginated response format
      final data = response.data;
      if (data is List) {
        return data
            .map((e) => Track.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (data is Map<String, dynamic>) {
        final tracks = (data['data'] as List?) ?? [];
        return tracks
            .map((e) => Track.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException {
      rethrow;
    }
  }
}
