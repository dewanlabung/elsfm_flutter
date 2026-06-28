import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elsfm/data/providers/api_client_provider.dart';
import 'package:elsfm/data/models/track.dart';

final artistDetailProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, id) async {
  final api = ref.watch(apiClientProvider);
  final artistRaw = await api.getArtist(id);
  final tracksResponse = await api.getArtistTracks(id, perPage: 20);
  return {
    'artist': artistRaw['artist'] ?? artistRaw,
    'tracks': tracksResponse.data,
  };
});
