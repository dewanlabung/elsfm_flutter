import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/track.dart';
import '../../../data/models/album.dart';
import '../../../data/providers/api_client_provider.dart';

final selectedArtistIdProvider = StateProvider<int?>((ref) => null);

final artistProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final artistId = ref.watch(selectedArtistIdProvider);
  if (artistId == null) return {};

  final apiClient = ref.watch(apiClientProvider);
  return await apiClient.getArtist(artistId);
});

final artistTracksProvider = FutureProvider<List<Track>>((ref) async {
  final artistId = ref.watch(selectedArtistIdProvider);
  if (artistId == null) return [];

  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.getArtistTracks(artistId);
  return response.data;
});

final artistAlbumsProvider = FutureProvider<List<Album>>((ref) async {
  final artistId = ref.watch(selectedArtistIdProvider);
  if (artistId == null) return [];

  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.getArtistAlbums(artistId);
  return response.data;
});
