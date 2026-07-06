import 'package:flutter/foundation.dart';

/// Event tracking service for ELSFM app.
/// Inspired by web's window.track events from ELSFM web.
/// Supports Firebase Analytics when available, with fallback to local logging.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();

  factory AnalyticsService() {
    return _instance;
  }

  AnalyticsService._internal();

  /// Track player event: play, pause, seek, skip, etc.
  Future<void> trackPlayerEvent({
    required String action,
    String? trackId,
    String? trackName,
    String? artistName,
  }) async {
    _logEvent('player_event', {
      'action': action,
      'track_id': trackId,
      'track_name': trackName,
      'artist_name': artistName,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track like/unlike action on a track.
  Future<void> trackLikeEvent({
    required int trackId,
    required String trackName,
    required bool isLiked,
  }) async {
    _logEvent('track_like', {
      'track_id': trackId,
      'track_name': trackName,
      'action': isLiked ? 'like' : 'unlike',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track follow action on a playlist.
  Future<void> trackFollowPlaylistEvent({
    required int playlistId,
    required String playlistName,
    required bool isFollowing,
  }) async {
    _logEvent('playlist_follow', {
      'playlist_id': playlistId,
      'playlist_name': playlistName,
      'action': isFollowing ? 'follow' : 'unfollow',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track search query.
  Future<void> trackSearchEvent({
    required String query,
    String? resultType,
    int? resultCount,
  }) async {
    _logEvent('search', {
      'query': query,
      'result_type': resultType,
      'result_count': resultCount,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track account menu interaction.
  Future<void> trackAccountMenuEvent({
    required String action,
  }) async {
    _logEvent('account_menu', {
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track theme toggle event.
  Future<void> trackThemeToggleEvent({
    required String theme,
  }) async {
    _logEvent('theme_toggle', {
      'theme': theme, // 'light' or 'dark'
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track player fullscreen/mini-player toggle.
  Future<void> trackPlayerOverlayEvent({
    required String action,
  }) async {
    _logEvent('player_overlay', {
      'action': action, // 'fullscreen' or 'mini'
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track authentication events.
  Future<void> trackAuthEvent({
    required String action,
    String? method,
  }) async {
    _logEvent('auth', {
      'action': action, // 'login', 'logout', 'signup'
      'method': method, // 'email', 'google', 'biometric'
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Log event to console in debug mode, send to analytics in production.
  void _logEvent(String eventName, Map<String, dynamic> params) {
    if (kDebugMode) {
      debugPrint('[Analytics] Event: $eventName - $params');
    }
    // TODO: Integrate with Firebase Analytics or other analytics provider
    // _firebaseAnalytics.logEvent(name: eventName, parameters: params);
  }
}
