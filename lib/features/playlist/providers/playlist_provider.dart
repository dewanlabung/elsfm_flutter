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
  final tracks = (response['tracks'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  return tracks.map((t) => Track.fromJson(t)).toList();
});
