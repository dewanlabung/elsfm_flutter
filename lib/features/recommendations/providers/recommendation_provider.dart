import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elsfm/data/providers/http_client_provider.dart';
import 'package:elsfm/data/repositories/recommendation_repository.dart';
import '../services/recommendation_service.dart';
import 'package:elsfm/data/models/recommendation.dart';
import 'package:elsfm/data/models/track.dart';

/// Recommendation repository provider — waits for Dio to be ready.
final recommendationRepositoryProvider =
    FutureProvider<RecommendationRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return RecommendationRepository(dio: dio);
});

/// Recommendation service provider — waits for the repository.
final recommendationServiceProvider =
    FutureProvider<RecommendationService>((ref) async {
  final repository = await ref.watch(recommendationRepositoryProvider.future);
  return RecommendationService(repository: repository);
});

/// Release Radar provider
final releaseRadarProvider = FutureProvider<Recommendation>((ref) async {
  final service = await ref.watch(recommendationServiceProvider.future);
  return service.getReleaseRadar();
});

/// Discover Weekly provider
final discoverWeeklyProvider = FutureProvider<Recommendation>((ref) async {
  final service = await ref.watch(recommendationServiceProvider.future);
  return service.getDiscoverWeekly();
});

/// Time Capsule provider
final timeCapsuleProvider = FutureProvider<Recommendation>((ref) async {
  final service = await ref.watch(recommendationServiceProvider.future);
  return service.getTimeCapsule();
});

/// Top Hits provider
final topHitsProvider =
    FutureProvider.family<Recommendation, String>((ref, period) async {
  final service = await ref.watch(recommendationServiceProvider.future);
  return service.getTopHits(period: period);
});

/// Mood Playlists provider
final moodPlaylistsProvider = FutureProvider<List<Recommendation>>((ref) async {
  final service = await ref.watch(recommendationServiceProvider.future);
  return service.getMoodPlaylists();
});

/// Recommendations for song provider
final recommendationsForSongProvider =
    FutureProvider.family<List<Track>, int>((ref, trackId) async {
  final service = await ref.watch(recommendationServiceProvider.future);
  return service.getRecommendationsForSong(trackId);
});

/// Featured recommendations provider
final featuredRecommendationsProvider =
    FutureProvider<List<Recommendation>>((ref) async {
  final results = await Future.wait([
    ref.watch(releaseRadarProvider.future),
    ref.watch(discoverWeeklyProvider.future),
    ref.watch(timeCapsuleProvider.future),
  ]);
  return results.cast<Recommendation>();
});
