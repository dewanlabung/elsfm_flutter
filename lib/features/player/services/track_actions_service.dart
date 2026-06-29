import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/models/track.dart';

class TrackActionsService {
  final Dio? _dio;

  TrackActionsService({Dio? dio}) : _dio = dio;

  Future<void> shareTrack(Track track) async {
    final artistName = track.artists.isNotEmpty ? track.artists[0].name : 'Unknown';
    final url = 'https://www.elsfm.com/tracks/${track.id}';
    await Share.share(
      '${track.name} by $artistName\n$url',
      subject: track.name,
    );
  }

  /// Download is handled by DownloadsNotifier; this method is kept for compatibility.
  Future<bool> downloadTrack(Track track) async {
    if (kDebugMode) debugPrint('downloadTrack: delegated to DownloadsNotifier');
    return true;
  }

  /// Add track to a playlist via POST /playlists/{playlistId}/tracks.
  Future<void> addTrackToPlaylist(Track track, String playlistId) async {
    if (_dio == null) throw Exception('Not authenticated');
    await _dio!.post(
      '/playlists/$playlistId/tracks',
      data: {'track_id': track.id},
      options: Options(contentType: 'application/json'),
    );
  }

  Future<void> addTrackToQueue(Track track) async {
    // Queue management is handled by PlayerNotifier.
    if (kDebugMode) debugPrint('addTrackToQueue: delegated to PlayerNotifier');
  }
}
