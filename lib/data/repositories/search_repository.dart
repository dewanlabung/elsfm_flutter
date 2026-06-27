import 'package:dio/dio.dart';
import '../models/track.dart';
import '../models/artist.dart';
import '../models/playlist.dart';

/// Repository for search functionality across songs, artists, and playlists.
///
/// BeMusic / Laravel backend notes (verified against https://www.elsfm.com/api/v1):
///
/// - List endpoints (`/tracks`, `/artists`, `/albums`) return:
///     `{ "pagination": { "data": [...], "current_page": 1, "next_page": 2, ... }, "status": "success" }`
/// - The `/trending` and `/homepage` routes serve the SPA shell (HTML), not JSON.
///   Use `/tracks?orderBy=plays&perPage=N` and `/artists?orderBy=plays&perPage=N` instead.
/// - The `/search?q=...` endpoint returns `{ "query": "", "results": [], "loader": "searchPage" }`
///   when hit server-side — it is an SPA page-initialisation route, not a REST search.
///   Use `/tracks?query=...` and `/artists?query=...` for real search.
class SearchRepository {
  final Dio dio;

  SearchRepository({required this.dio});

  /// Extract `pagination.data` from a BeMusic paginated response.
  List<dynamic> _extractPageData(dynamic responseData) {
    if (responseData is Map) {
      final pagination = responseData['pagination'];
      if (pagination is Map) {
        final data = pagination['data'];
        if (data is List) return data;
      }
      // Fallback: flat `data` key.
      final data = responseData['data'];
      if (data is List) return data;
    }
    if (responseData is List) return responseData;
    return [];
  }

  /// Search across tracks and artists.
  ///
  /// Uses `/tracks?query=...` and `/artists?query=...` because the BeMusic
  /// `/search` route is an SPA initialisation endpoint, not a REST API.
  Future<Map<String, dynamic>> search({
    required String query,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final results = await Future.wait([
        dio.get('/tracks', queryParameters: {
          'query': query,
          'page': page,
          'perPage': perPage,
        }),
        dio.get('/artists', queryParameters: {
          'query': query,
          'page': page,
          'perPage': perPage,
        }),
      ]);

      final songs = _extractPageData(results[0].data)
          .map((e) => Track.fromJson(e as Map<String, dynamic>))
          .toList();

      final artists = _extractPageData(results[1].data)
          .map((e) => Artist.fromJson(e as Map<String, dynamic>))
          .toList();

      return {
        'songs': songs,
        'artists': artists,
        'playlists': <Playlist>[],
      };
    } on DioException {
      rethrow;
    }
  }

  /// Fetch tracks, optionally filtered by artist or album.
  Future<List<Track>> searchSongs({
    int? artistId,
    int? albumId,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'perPage': perPage,
        if (artistId != null) 'artist_id': artistId,
        if (albumId != null) 'album_id': albumId,
      };

      final response = await dio.get('/tracks', queryParameters: params);
      return _extractPageData(response.data)
          .map((e) => Track.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      rethrow;
    }
  }

  /// Get trending / popular songs or artists.
  ///
  /// The BeMusic `/trending` route serves the SPA HTML shell, not JSON.
  /// This method uses `/tracks?orderBy=plays` and `/artists?orderBy=plays`
  /// to achieve the same result via the REST API.
  Future<Map<String, dynamic>> getTrending({
    String type = 'songs', // 'songs' or 'artists'
    int perPage = 50,
  }) async {
    try {
      if (type == 'artists') {
        final response = await dio.get('/artists', queryParameters: {
          'orderBy': 'plays',
          'orderDir': 'desc',
          'perPage': perPage,
        });
        return {
          'artists': _extractPageData(response.data)
              .map((e) => Artist.fromJson(e as Map<String, dynamic>))
              .toList(),
        };
      } else {
        final response = await dio.get('/tracks', queryParameters: {
          'orderBy': 'plays',
          'orderDir': 'desc',
          'perPage': perPage,
        });
        return {
          'songs': _extractPageData(response.data)
              .map((e) => Track.fromJson(e as Map<String, dynamic>))
              .toList(),
        };
      }
    } on DioException {
      rethrow;
    }
  }
}
