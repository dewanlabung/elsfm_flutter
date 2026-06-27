import 'package:dio/dio.dart';
import '../models/recommendation.dart';
import '../models/track.dart';

/// Repository for recommendations (Release Radar, Discover Weekly, etc.)
class RecommendationRepository {
  final Dio dio;

  RecommendationRepository({required this.dio});

  /// Get curated recommendations for current user
  /// Authorization: User must be authenticated
  Future<Recommendation> getRecommendation({
    required String type, // 'release_radar', 'discover_weekly', 'top_hits', etc.
  }) async {
    try {
      final response = await dio.get(
        '/api/v1/recommendations/$type',
      );

      return Recommendation.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  /// Get Release Radar (new releases from followed artists)
  /// Authorization: User must be authenticated
  Future<Recommendation> getReleaseRadar() async {
    try {
      final response = await dio.get('/api/v1/recommendations/release_radar');
      return Recommendation.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  /// Get Discover Weekly (personalized playlist)
  /// Authorization: User must be authenticated
  Future<Recommendation> getDiscoverWeekly() async {
    try {
      final response = await dio.get('/api/v1/recommendations/discover_weekly');
      return Recommendation.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  /// Get Time Capsule (throwback playlist)
  /// Authorization: User must be authenticated
  Future<Recommendation> getTimeCapsule() async {
    try {
      final response = await dio.get('/api/v1/recommendations/time_capsule');
      return Recommendation.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  /// Get Top Hits (current charts)
  /// Authorization: None (public)
  Future<Recommendation> getTopHits({
    String period = 'week', // 'day', 'week', 'month'
  }) async {
    try {
      final response = await dio.get(
        '/api/v1/recommendations/top_hits',
        queryParameters: {
          'period': period,
        },
      );

      return Recommendation.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  /// Get mood-based playlists
  /// Authorization: None (public)
  Future<List<Recommendation>> getMoodPlaylists() async {
    try {
      final response = await dio.get('/api/v1/recommendations/moods');

      return ((response.data as List?) ?? [])
          .map((e) => Recommendation.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      rethrow;
    }
  }

  /// Get recommendations based on a specific song
  /// Finds similar songs, related artists, and collaborative suggestions
  /// Authorization: None (public)
  Future<List<Track>> getRecommendationsForSong({
    required int trackId,
    int limit = 50,
  }) async {
    try {
      final response = await dio.get(
        '/api/v1/recommendations/based-on/$trackId',
        queryParameters: {
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

  /// Get recommendations based on multiple songs (for playlist generation)
  /// Authorization: None (public)
  Future<List<Track>> getRecommendationsForSongs({
    required List<int> trackIds,
    int limit = 50,
  }) async {
    try {
      final response = await dio.get(
        '/api/v1/recommendations/based-on',
        queryParameters: {
          'track_ids': trackIds.join(','),
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

  /// Refresh recommendation (get updated version)
  /// Authorization: User must be authenticated
  Future<Recommendation> refreshRecommendation({
    required String type,
  }) async {
    try {
      final response = await dio.post(
        '/api/v1/recommendations/$type/refresh',
      );

      return Recommendation.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  /// Get all available recommendation types
  /// Authorization: None (public)
  Future<List<String>> getAvailableTypes() async {
    try {
      final response = await dio.get('/api/v1/recommendations/types');

      return ((response.data as List?) ?? [])
          .map((e) => e.toString())
          .toList();
    } on DioException {
      rethrow;
    }
  }
}
