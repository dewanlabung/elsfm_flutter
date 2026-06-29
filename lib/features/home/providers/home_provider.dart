import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/album.dart';
import '../../../data/models/genre.dart';
import '../../../data/models/playlist.dart';
import '../../../data/models/track.dart';
import '../../../data/providers/api_client_provider.dart';

class HomeData {
  final List<Playlist> featuredPlaylists;
  final List<Genre> genres;
  final List<Track> topTracks;
  final List<Album> newReleases;

  const HomeData({
    required this.featuredPlaylists,
    required this.genres,
    required this.topTracks,
    required this.newReleases,
  });
}

final homeDataProvider = FutureProvider<HomeData>((ref) async {
  final api = ref.watch(apiClientProvider);

  final results = await Future.wait([
    api.getPlaylists(perPage: 10),
    api.getGenres(perPage: 8),
    api.getTracks(perPage: 10, orderBy: 'plays', orderDir: 'desc'),
    api.getAlbums(perPage: 10),
  ]);

  return HomeData(
    featuredPlaylists: (results[0] as dynamic).data as List<Playlist>,
    genres: results[1] as List<Genre>,
    topTracks: (results[2] as dynamic).data as List<Track>,
    newReleases: (results[3] as dynamic).data as List<Album>,
  );
});
