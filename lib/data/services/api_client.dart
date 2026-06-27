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
        queryParameters: {'page': page, 'per_page': perPage});
    return _parsePaginationResponse(
      response.data!,
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
  Future<List<Genre>> getGenres() async {
    final response = await dio.get<List<dynamic>>('/genres');
    return (response.data ?? [])
        .map((e) => Genre.fromJson(e as Map<String, dynamic>))
        .toList();
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
