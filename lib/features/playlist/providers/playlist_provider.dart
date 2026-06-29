import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/track.dart';
import '../../../data/providers/api_client_provider.dart';

final selectedPlaylistIdProvider = StateProvider<int?>((ref) => null);

final playlistProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final playlistId = ref.watch(selectedPlaylistIdProvider);
  if (playlistId == null) return {};

  final apiClient = ref.watch(apiClientProvider);
  return await apiClient.getPlaylist(playlistId);
});

final playlistTracksProvider = FutureProvider<List<Track>>((ref) async {
  final playlistId = ref.watch(selectedPlaylistIdProvider);
  if (playlistId == null) return [];

  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.getPlaylist(playlistId);
  return _parseTracks(response['tracks']);
});

/// BeMusic returns tracks either as a plain List or as a pagination Map
/// {"data": [...], "current_page": 1, ...}. Handle both.
List<Track> _parseTracks(dynamic raw) {
  List<dynamic> list = [];
  if (raw is List) {
    list = raw;
  } else if (raw is Map) {
    list = (raw['data'] as List?) ?? [];
  }
  return list
      .whereType<Map<String, dynamic>>()
      .map((t) => Track.fromJson(t))
      .toList();
}
