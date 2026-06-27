import 'package:dio/dio.dart';
import '../models/user_library.dart';
import '../models/track.dart';

/// Repository for user library (favorites, history, etc.)
class UserLibraryRepository {
  final Dio dio;

  UserLibraryRepository({required this.dio});

  /// Get user's complete library (favorites, history, statistics)
  /// Authorization: User must be authenticated
  Future<UserLibrary> getUserLibrary() async {
    try {
      final response = await dio.get('/library');
      return UserLibrary.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  /// Get user's favorite songs
  /// Authorization: User must be authenticated
  Future<List<Track>> getFavorites({
    int page = 1,
    int limit = 50,
    String sortBy = 'added_at', // 'added_at' or 'name'
  }) async {
    try {
      final response = await dio.get(
        '/library/favorites',
        queryParameters: {
          'page': page,
          'limit': limit,
          'sort_by': sortBy,
        },
      );

      return ((response.data as List?) ?? [])
          .map((e) => Track.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      rethrow;
    }
  }

  /// Add a song to favorites
  /// Authorization: User must be authenticated
  Future<void> addFavorite(int trackId) async {
    try {
      await dio.post(
        '/library/favorites/$trackId',
      );
    } on DioException {
      rethrow;
    }
  }

  /// Remove a song from favorites
  /// Authorization: User must be authenticated
  Future<void> removeFavorite(int trackId) async {
    try {
      await dio.delete(
        '/library/favorites/$trackId',
      );
    } on DioException {
      rethrow;
    }
  }

  /// Check if a song is favorited
  /// Authorization: User must be authenticated
  Future<bool> isFavorited(int trackId) async {
    try {
      final response = await dio.get(
        '/library/favorites/$trackId/check',
      );

      return response.data?['is_favorited'] as bool? ?? false;
    } on DioException {
      rethrow;
    }
  }

  /// Get user's play history
  /// Authorization: User must be authenticated
  Future<List<Track>> getHistory({
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final response = await dio.get(
        '/library/history',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      return ((response.data as List?) ?? [])
          .map((e) => Track.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      rethrow;
    }
  }

  /// Log a song play (record listening history)
  /// Authorization: User must be authenticated
  Future<void> logPlay({
    required int trackId,
    int? durationPlayedSeconds,
  }) async {
    try {
      await dio.post(
        '/library/history/$trackId',
        data: {
          if (durationPlayedSeconds != null) 'duration_played_seconds': durationPlayedSeconds,
        },
      );
    } on DioException {
      rethrow;
    }
  }

  /// Clear user's play history
  /// Authorization: User must be authenticated
  Future<void> clearHistory() async {
    try {
      await dio.delete('/library/history');
    } on DioException {
      rethrow;
    }
  }

  /// Get listening statistics for user
  /// Authorization: User must be authenticated
  Future<Map<String, dynamic>> getStatistics({
    String period = 'month', // 'week', 'month', 'year', 'all'
  }) async {
    try {
      final response = await dio.get(
        '/library/statistics',
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
  Future<List<Track>> getTopTracks({
    String period = 'month',
    int limit = 20,
  }) async {
    try {
      final response = await dio.get(
        '/library/top-tracks',
        queryParameters: {
          'period': period,
          'limit': limit,
        },
      );

      return ((response.data as List?) ?? [])
          .map((e) => Track.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      rethrow;
    }
  }
}
