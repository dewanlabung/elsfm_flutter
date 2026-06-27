import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elsfm/data/providers/http_client_provider.dart';
import 'package:elsfm/data/repositories/recommendation_repository.dart';
import '../services/recommendation_service.dart';
import 'package:elsfm/data/models/recommendation.dart';
import 'package:elsfm/data/models/track.dart';

/// Recommendation repository provider
final recommendationRepositoryProvider = Provider<RecommendationRepository>((ref) {
  final dio = ref.watch(dioProvider).requireValue;
  return RecommendationRepository(dio: dio);
});

/// Recommendation service provider
final recommendationServiceProvider = Provider<RecommendationService>((ref) {
  final repository = ref.watch(recommendationRepositoryProvider);
  return RecommendationService(repository: repository);
});

/// Release Radar provider
final releaseRadarProvider = FutureProvider<Recommendation>((ref) async {
  final service = ref.watch(recommendationServiceProvider);
  return await service.getReleaseRadar();
});

/// Discover Weekly provider
final discoverWeeklyProvider = FutureProvider<Recommendation>((ref) async {
  final service = ref.watch(recommendationServiceProvider);
  return await service.getDiscoverWeekly();
});

/// Time Capsule provider
final timeCapsuleProvider = FutureProvider<Recommendation>((ref) async {
  final service = ref.watch(recommendationServiceProvider);
  return await service.getTimeCapsule();
});

/// Top Hits provider
final topHitsProvider = FutureProvider.family<Recommendation, String>((ref, period) async {
  final service = ref.watch(recommendationServiceProvider);
  return await service.getTopHits(period: period);
});

/// Mood Playlists provider
final moodPlaylistsProvider = FutureProvider<List<Recommendation>>((ref) async {
  final service = ref.watch(recommendationServiceProvider);
  return await service.getMoodPlaylists();
});

/// Recommendations for song provider
final recommendationsForSongProvider = FutureProvider.family<List<Track>, int>((ref, trackId) async {
  final service = ref.watch(recommendationServiceProvider);
  return await service.getRecommendationsForSong(trackId);
});

/// Featured recommendations provider
final featuredRecommendationsProvider = FutureProvider<List<Recommendation>>((ref) async {
  try {
    // Load all featured recommendations in parallel
    final service = ref.watch(recommendationServiceProvider);
    final results = await Future.wait([
      ref.watch(releaseRadarProvider.future),
      ref.watch(discoverWeeklyProvider.future),
      ref.watch(timeCapsuleProvider.future),
    ]);
    return results.cast<Recommendation>();
  } catch (e) {
    throw Exception('Failed to load recommendations: $e');
  }
});
