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
  final tracks = (response['tracks'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  return tracks.map((t) => Track.fromJson(t)).toList();
});
