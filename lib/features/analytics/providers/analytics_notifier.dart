import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/analytics_service.dart';

/// Notifier for analytics operations.
/// Provides a reactive interface to the analytics service.
class AnalyticsNotifier extends StateNotifier<void> {
  final AnalyticsService _analytics = AnalyticsService();

  AnalyticsNotifier() : super(null);

  /// Track player event: play, pause, seek, skip, etc.
  Future<void> trackPlayerEvent({
    required String action,
    String? trackId,
    String? trackName,
    String? artistName,
  }) =>
      _analytics.trackPlayerEvent(
        action: action,
        trackId: trackId,
        trackName: trackName,
        artistName: artistName,
      );

  /// Track like/unlike action on a track.
  Future<void> trackLikeEvent({
    required int trackId,
    required String trackName,
    required bool isLiked,
  }) =>
      _analytics.trackLikeEvent(
        trackId: trackId,
        trackName: trackName,
        isLiked: isLiked,
      );

  /// Track follow action on a playlist.
  Future<void> trackFollowPlaylistEvent({
    required int playlistId,
    required String playlistName,
    required bool isFollowing,
  }) =>
      _analytics.trackFollowPlaylistEvent(
        playlistId: playlistId,
        playlistName: playlistName,
        isFollowing: isFollowing,
      );

  /// Track search query.
  Future<void> trackSearchEvent({
    required String query,
    String? resultType,
    int? resultCount,
  }) =>
      _analytics.trackSearchEvent(
        query: query,
        resultType: resultType,
        resultCount: resultCount,
      );

  /// Track account menu interaction.
  Future<void> trackAccountMenuEvent({
    required String action,
  }) =>
      _analytics.trackAccountMenuEvent(action: action);

  /// Track theme toggle event.
  Future<void> trackThemeToggleEvent({
    required String theme,
  }) =>
      _analytics.trackThemeToggleEvent(theme: theme);

  /// Track player fullscreen/mini-player toggle.
  Future<void> trackPlayerOverlayEvent({
    required String action,
  }) =>
      _analytics.trackPlayerOverlayEvent(action: action);

  /// Track authentication events.
  Future<void> trackAuthEvent({
    required String action,
    String? method,
  }) =>
      _analytics.trackAuthEvent(action: action, method: method);
}

/// Riverpod provider for analytics operations.
final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, void>((ref) {
  return AnalyticsNotifier();
});
