import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../data/models/track.dart';

class TrackActionsService {
  /// Share a track with other apps.
  Future<void> shareTrack(Track track) async {
    try {
      final artistNames = track.artists.map((a) => a.name).join(', ');
      final url = 'https://www.elsfm.com/tracks/${track.id}';
      final message =
          '${track.name}${artistNames.isNotEmpty ? ' by $artistNames' : ''}\n$url';

      await Share.share(message, subject: track.name);
    } catch (e) {
      if (kDebugMode) debugPrint('Error sharing track: $e');
      rethrow;
    }
  }

  /// Download a track file.
  Future<bool> downloadTrack(Track track) async {
    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        if (kDebugMode) debugPrint('Storage permission denied');
        return false;
      }

      if (kDebugMode) debugPrint('Downloading track: ${track.name}');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Error downloading track: $e');
      return false;
    }
  }

  /// Add track to a specific playlist.
  Future<void> addTrackToPlaylist(Track track, String playlistId) async {
    try {
      if (kDebugMode) {
        debugPrint('Adding ${track.name} to playlist $playlistId');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error adding track to playlist: $e');
      rethrow;
    }
  }

  /// Add track to queue.
  Future<void> addTrackToQueue(Track track) async {
    try {
      if (kDebugMode) debugPrint('Adding ${track.name} to queue');
    } catch (e) {
      if (kDebugMode) debugPrint('Error adding track to queue: $e');
      rethrow;
    }
  }
}
