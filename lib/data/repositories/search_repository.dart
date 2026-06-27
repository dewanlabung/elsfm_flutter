import 'package:dio/dio.dart';
import '../models/track.dart';
import '../models/artist.dart';
import '../models/playlist.dart';

/// Repository for search functionality across songs, artists, and playlists
class SearchRepository {
  final Dio dio;

  SearchRepository({required this.dio});

  /// Search across all content (songs, artists, playlists)
  /// Returns paginated results: {songs: Track[], artists: Artist[], playlists: Playlist[]}
  Future<Map<String, dynamic>> search({
    required String query,
    int page = 1,
    int limit = 20,
    List<String>? filters, // genre, year, etc.
  }) async {
    try {
      final params = <String, dynamic>{
        'q': query,
        'page': page,
        'limit': limit,
        if (filters != null) 'filters': filters.join(','),
      };

      final response = await dio.get(
        '/api/v1/search',
        queryParameters: params,
      );

      return {
        'songs': ((response.data?['songs'] as List?) ?? [])
            .map((e) => Track.fromJson(e as Map<String, dynamic>))
            .toList(),
        'artists': ((response.data?['artists'] as List?) ?? [])
            .map((e) => Artist.fromJson(e as Map<String, dynamic>))
            .toList(),
        'playlists': ((response.data?['playlists'] as List?) ?? [])
            .map((e) => Playlist.fromJson(e as Map<String, dynamic>))
            .toList(),
        'page': response.data?['page'],
        'total': response.data?['total'],
      };
    } on DioException {
      rethrow;
    }
  }

  /// Search songs by artist or album
  Future<List<Track>> searchSongs({
    int? artistId,
    int? albumId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (artistId != null) 'artist_id': artistId,
        if (albumId != null) 'album_id': albumId,
      };

      final response = await dio.get(
        '/api/v1/songs',
        queryParameters: params,
      );

      return ((response.data as List?) ?? [])
          .map((e) => Track.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      rethrow;
    }
  }

  /// Get trending songs/artists
  Future<Map<String, dynamic>> getTrending({
    String type = 'songs', // 'songs' or 'artists'
    String period = 'week', // 'day', 'week', 'month'
    int limit = 50,
  }) async {
    try {
      final response = await dio.get(
        '/api/v1/trending',
        queryParameters: {
          'type': type,
          'period': period,
          'limit': limit,
        },
      );

      if (type == 'songs') {
        return {
          'songs': ((response.data as List?) ?? [])
              .map((e) => Track.fromJson(e as Map<String, dynamic>))
              .toList(),
        };
      } else {
        return {
          'artists': ((response.data as List?) ?? [])
              .map((e) => Artist.fromJson(e as Map<String, dynamic>))
              .toList(),
        };
      }
    } on DioException {
      rethrow;
    }
  }
}
