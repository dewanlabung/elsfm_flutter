import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../data/models/track.dart';

class TrackActionsService {
  /// Share a track with other apps
  Future<void> shareTrack(Track track) async {
    try {
      final url = 'https://www.elsfm.com/tracks/${track.id}';
      final artistName = track.artists.isNotEmpty ? track.artists[0].name : 'Unknown';
      final message = '${track.name} by $artistName\n$url';

      await Share.share(
        message,
        subject: track.name,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error sharing track: $e');
      }
      rethrow;
    }
  }

  /// Download a track file
  Future<bool> downloadTrack(Track track) async {
    try {
      // Request storage permission
      final status = await Permission.storage.request();

      if (!status.isGranted) {
        if (kDebugMode) {
          debugPrint('Storage permission denied');
        }
        return false;
      }

      // TODO: Implement actual download using downloads_path_provider
      // This would:
      // 1. Get the track stream URL
      // 2. Download to app's cache or documents directory
      // 3. Show download progress
      // 4. Save metadata

      if (kDebugMode) {
        debugPrint('Downloading track: ${track.name}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error downloading track: $e');
      }
      return false;
    }
  }

  /// Add track to a specific playlist
  Future<void> addTrackToPlaylist(Track track, String playlistId) async {
    try {
      // TODO: Implement API call to add track to playlist
      // POST /api/v1/playlists/{playlistId}/tracks
      // Body: { "track_id": track.id }

      if (kDebugMode) {
        debugPrint('Adding ${track.name} to playlist $playlistId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error adding track to playlist: $e');
      }
      rethrow;
    }
  }

  /// Add track to queue
  Future<void> addTrackToQueue(Track track) async {
    try {
      // This is typically handled by the player provider
      // But we can use this service to track analytics or cache
      if (kDebugMode) {
        debugPrint('Adding ${track.name} to queue');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error adding track to queue: $e');
      }
      rethrow;
    }
  }
}
