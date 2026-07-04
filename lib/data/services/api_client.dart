import 'package:dio/dio.dart';
import '../models/backend_response.dart';
import '../models/track.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/playlist.dart';
import '../models/channel.dart';
import '../models/genre.dart';
import '../models/user.dart';

class ApiClient {
  final Dio dio;

  ApiClient(this.dio);

  // Channels
  Future<BackendResponse<List<Channel>>> getChannels({int? userId}) async {
    final params = userId != null ? {'userId': userId} : <String, dynamic>{};
    final response = await dio.get<Map<String, dynamic>>('/channel', queryParameters: params);
    final data = response.data!;
    final channels = (data['data'] as List)
        .map((e) => Channel.fromJson(e as Map<String, dynamic>))
        .toList();
    return BackendResponse(data: channels);
  }

  Future<BackendResponse<Map<String, dynamic>>> getChannel(int id) async {
    final response = await dio.get<Map<String, dynamic>>('/channel/$id');
    return BackendResponse(data: response.data!);
  }

  // Artists
  Future<PaginationResponse<Artist>> getArtists({
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await dio.get<Map<String, dynamic>>('/artists',
        queryParameters: {'page': page, 'per_page': perPage});
    return _parsePaginationResponse(
      response.data!,
      (e) => Artist.fromJson(e as Map<String, dynamic>),
    );
  }

  Future<Map<String, dynamic>> getArtist(
    int id, {
    String loader = 'artist',
  }) async {
    final response = await dio.get<Map<String, dynamic>>('/artists/$id',
        queryParameters: {'loader': loader});
    return response.data!;
  }

  Future<PaginationResponse<Track>> getArtistTracks(
    int id, {
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await dio.get<Map<String, dynamic>>('/artists/$id/tracks',
        queryParameters: {'page': page, 'per_page': perPage});
    return _parsePaginationResponse(
      response.data!,
      (e) => Track.fromJson(e as Map<String, dynamic>),
    );
  }

  Future<PaginationResponse<Album>> getArtistAlbums(
    int id, {
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await dio.get<Map<String, dynamic>>('/artists/$id/albums',
        queryParameters: {'page': page, 'per_page': perPage});
    return _parsePaginationResponse(
      response.data!,
      (e) => Album.fromJson(e as Map<String, dynamic>),
    );
  }

  // Albums
  Future<PaginationResponse<Album>> getAlbums({
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await dio.get<Map<String, dynamic>>('/albums',
        queryParameters: {'page': page, 'per_page': perPage});
    return _parsePaginationResponse(
      response.data!,
      (e) => Album.fromJson(e as Map<String, dynamic>),
    );
  }

  Future<Map<String, dynamic>> getAlbum(int id) async {
    final response = await dio.get<Map<String, dynamic>>('/albums/$id');
    return response.data!;
  }

  // Tracks
  Future<Track> getTrack(int id) async {
    final response = await dio.get<Map<String, dynamic>>('/tracks/$id');
    return Track.fromJson(response.data!);
  }

  // Playlists
  Future<PaginationResponse<Playlist>> getPlaylists({
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await dio.get<Map<String, dynamic>>('/playlists',
        queryParameters: {'page': page, 'perPage': perPage});
    final data = response.data!;
    // Real API wraps in 'pagination' key
    final inner = data.containsKey('pagination')
        ? data['pagination'] as Map<String, dynamic>
        : data;
    return _parsePaginationResponse(
      inner,
      (e) => Playlist.fromJson(e as Map<String, dynamic>),
    );
  }

  Future<Map<String, dynamic>> getPlaylist(int id) async {
    final response = await dio.get<Map<String, dynamic>>('/playlists/$id');
    return response.data!;
  }

  // Search
  Future<Map<String, dynamic>> search({
    required String query,
    String type = 'track,artist,album,playlist',
    int limit = 20,
  }) async {
    final response = await dio.get<Map<String, dynamic>>('/search',
        queryParameters: {'q': query, 'type': type, 'limit': limit});
    return response.data!;
  }

  // User
  Future<User> getCurrentUser() async {
    final response = await dio.get<Map<String, dynamic>>('/user');
    final data = response.data!;
    return User.fromJson((data['user'] ?? data) as Map<String, dynamic>);
  }

  Future<PaginationResponse<Track>> getLikedTracks(
    int userId, {
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
        '/users/$userId/liked-tracks',
        queryParameters: {'page': page, 'per_page': perPage});
    return _parsePaginationResponse(
      response.data!,
      (e) => Track.fromJson(e as Map<String, dynamic>),
    );
  }

  Future<PaginationResponse<Album>> getLikedAlbums(
    int userId, {
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
        '/users/$userId/liked-albums',
        queryParameters: {'page': page, 'per_page': perPage});
    return _parsePaginationResponse(
      response.data!,
      (e) => Album.fromJson(e as Map<String, dynamic>),
    );
  }

  Future<PaginationResponse<Artist>> getLikedArtists(
    int userId, {
    int page = 1,
    int perPage = 50,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
        '/users/$userId/liked-artists',
        queryParameters: {'page': page, 'per_page': perPage});
    return _parsePaginationResponse(
      response.data!,
      (e) => Artist.fromJson(e as Map<String, dynamic>),
    );
  }

  Future<PaginationResponse<Playlist>> getUserPlaylists(
    int userId, {
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
        '/users/$userId/playlists',
        queryParameters: {'page': page, 'per_page': perPage});
    return _parsePaginationResponse(
      response.data!,
      (e) => Playlist.fromJson(e as Map<String, dynamic>),
    );
  }

  // Genres
  Future<List<Genre>> getGenres({int perPage = 20}) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/genres',
      queryParameters: {'perPage': perPage},
    );
    final data = response.data!;
    // The API may return a pagination wrapper or a plain list.
    if (data.containsKey('pagination')) {
      final items = (data['pagination']['data'] as List? ?? []);
      return items.map((e) => Genre.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (data.containsKey('data')) {
      return (data['data'] as List? ?? [])
          .map((e) => Genre.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // Top tracks
  Future<PaginationResponse<Track>> getTracks({
    int page = 1,
    int perPage = 20,
    String orderBy = 'plays',
    String orderDir = 'desc',
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/tracks',
      queryParameters: {
        'page': page,
        'perPage': perPage,
        'orderBy': orderBy,
        'orderDir': orderDir,
      },
    );
    final data = response.data!;
    // API wraps in pagination key
    final inner = data.containsKey('pagination')
        ? data['pagination'] as Map<String, dynamic>
        : data;
    final items = (inner['data'] as List? ?? [])
        .map((e) => Track.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginationResponse(
      data: items,
      currentPage: inner['current_page'] as int? ?? 1,
      lastPage: inner['last_page'] as int? ?? 1,
      total: inner['total'] as int? ?? 0,
      perPage: inner['per_page'] as int? ?? perPage,
    );
  }

  // Lyrics
  Future<Map<String, dynamic>?> getTrackLyrics(int trackId) async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/tracks/$trackId/lyrics');
      return response.data;
    } catch (_) {
      return null;
    }
  }

  // Artist bio
  Future<String?> getArtistBio(int artistId) async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/artists/$artistId/bio');
      return response.data?['bio']?['content'] as String?;
    } catch (_) {
      return null;
    }
  }

  // Similar artists
  Future<List<Map<String, dynamic>>> getSimilarArtists(int artistId) async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/artists/$artistId/similar');
      final data = response.data?['artists']?['data'] as List? ?? [];
      return data.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  // Log a play after track starts
  Future<void> logTrackPlay(int trackId) async {
    try {
      await dio.post<void>('/tracks/plays/$trackId/log');
    } catch (_) {}
  }

  // Notifications
  Future<List<Map<String, dynamic>>> getNotifications({int page = 1}) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/notifications',
      queryParameters: {'page': page},
    );
    final data = response.data?['pagination']?['data'] as List? ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> markNotificationsRead({List<int>? ids}) async {
    await dio.post<void>(
      '/notifications/mark-as-read',
      data: ids != null ? {'ids': ids} : null,
    );
  }

  // Comments
  Future<List<Map<String, dynamic>>> getComments({
    required String type,
    required int id,
    int page = 1,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/commentable/comments',
      queryParameters: {'commentable_type': type, 'commentable_id': id, 'page': page},
    );
    final data = response.data?['pagination']?['data'] as List? ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> postComment({required String type, required int id, required String content}) async {
    await dio.post<void>('/comment', data: {
      'content': content,
      'commentable_type': type,
      'commentable_id': id,
    });
  }

  PaginationResponse<T> _parsePaginationResponse<T>(
    Map<String, dynamic> data,
    T Function(dynamic) fromJson,
  ) {
    final items = ((data['data'] ?? []) as List)
        .map((e) => fromJson(e))
        .toList();
    return PaginationResponse(
      data: items,
      currentPage: data['current_page'] as int? ?? 1,
      lastPage: data['last_page'] as int? ?? 1,
      total: data['total'] as int? ?? 0,
      perPage: data['per_page'] as int? ?? 20,
    );
  }
}
