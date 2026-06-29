import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/track.dart';
import '../../../data/providers/api_client_provider.dart';

final selectedAlbumIdProvider = StateProvider<int?>((ref) => null);

final albumProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final albumId = ref.watch(selectedAlbumIdProvider);
  if (albumId == null) return {};

  final apiClient = ref.watch(apiClientProvider);
  return await apiClient.getAlbum(albumId);
});

final albumTracksProvider = FutureProvider<List<Track>>((ref) async {
  final albumId = ref.watch(selectedAlbumIdProvider);
  if (albumId == null) return [];

  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.getAlbum(albumId);
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
