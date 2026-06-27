import 'package:elsfm/data/repositories/recommendation_repository.dart';
import 'package:elsfm/data/models/recommendation.dart';
import 'package:elsfm/data/models/track.dart';

/// Recommendations service (Release Radar, Discover Weekly, etc.)
class RecommendationService {
  final RecommendationRepository repository;

  RecommendationService({required this.repository});

  Future<Recommendation> getReleaseRadar() async {
    try {
      return await repository.getReleaseRadar();
    } catch (e) {
      throw RecommendationException('Failed to load Release Radar: $e');
    }
  }

  Future<Recommendation> getDiscoverWeekly() async {
    try {
      return await repository.getDiscoverWeekly();
    } catch (e) {
      throw RecommendationException('Failed to load Discover Weekly: $e');
    }
  }

  Future<Recommendation> getTimeCapsule() async {
    try {
      return await repository.getTimeCapsule();
    } catch (e) {
      throw RecommendationException('Failed to load Time Capsule: $e');
    }
  }

  Future<Recommendation> getTopHits({String period = 'week'}) async {
    try {
      return await repository.getTopHits(period: period);
    } catch (e) {
      throw RecommendationException('Failed to load Top Hits: $e');
    }
  }

  Future<List<Recommendation>> getMoodPlaylists() async {
    try {
      return await repository.getMoodPlaylists();
    } catch (e) {
      throw RecommendationException('Failed to load mood playlists: $e');
    }
  }

  Future<List<Track>> getRecommendationsForSong(int trackId) async {
    try {
      return await repository.getRecommendationsForSong(trackId: trackId);
    } catch (e) {
      throw RecommendationException('Failed to get recommendations: $e');
    }
  }

  Future<List<Track>> getRecommendationsForSongs(List<int> trackIds) async {
    try {
      return await repository.getRecommendationsForSongs(trackIds: trackIds);
    } catch (e) {
      throw RecommendationException('Failed to get recommendations: $e');
    }
  }
}

class RecommendationException implements Exception {
  final String message;
  RecommendationException(this.message);

  @override
  String toString() => 'RecommendationException: $message';
}
