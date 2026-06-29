import 'package:dio/dio.dart';
import '../models/user.dart';
import '../models/track.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/playlist.dart';
import '../models/backend_response.dart';
import '../models/app_error.dart';

/// Repository for user-scoped swagger endpoints:
///   GET /users/{id}
///   GET /users/me/liked-tracks
///   GET /users/me/liked-albums
///   GET /users/me/liked-artists
///   GET /users/me/playlists
///   GET /users/me/followers
///   GET /users/me/followed-users
class UserRepository {
  final Dio dio;

  UserRepository({required this.dio});

  PaginationResponse<T> _parsePagination<T>(
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final inner = data.containsKey('pagination')
        ? data['pagination'] as Map<String, dynamic>
        : data;
    final items = ((inner['data'] ?? []) as List)
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginationResponse(
      data: items,
      currentPage: (inner['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (inner['last_page'] as num?)?.toInt() ?? 1,
      total: (inner['total'] as num?)?.toInt() ?? 0,
      perPage: (inner['per_page'] as num?)?.toInt() ?? 20,
    );
  }

  /// GET /users/{id}
  ///
  /// Use [id] = `'me'` for the currently authenticated user.
  Future<User> getUser(String id) async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/users/$id');
      final body = response.data!;
      final userJson = body['user'] as Map<String, dynamic>? ?? body;
      return User.fromJson(userJson);
    } catch (e) {
      throw mapToAppError(e);
    }
  }

  /// GET /users/me/liked-tracks
  Future<PaginationResponse<Track>> getLikedTracks({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/users/me/liked-tracks',
        queryParameters: {'page': page, 'perPage': perPage},
      );
      return _parsePagination(response.data!, Track.fromJson);
    } catch (e) {
      throw mapToAppError(e);
    }
  }

  /// GET /users/me/liked-albums
  Future<PaginationResponse<Album>> getLikedAlbums({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/users/me/liked-albums',
        queryParameters: {'page': page, 'perPage': perPage},
      );
      return _parsePagination(response.data!, Album.fromJson);
    } catch (e) {
      throw mapToAppError(e);
    }
  }

  /// GET /users/me/liked-artists
  Future<PaginationResponse<Artist>> getLikedArtists({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/users/me/liked-artists',
        queryParameters: {'page': page, 'perPage': perPage},
      );
      return _parsePagination(response.data!, Artist.fromJson);
    } catch (e) {
      throw mapToAppError(e);
    }
  }

  /// GET /users/me/playlists
  Future<PaginationResponse<Playlist>> getUserPlaylists({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/users/me/playlists',
        queryParameters: {'page': page, 'perPage': perPage},
      );
      return _parsePagination(response.data!, Playlist.fromJson);
    } catch (e) {
      throw mapToAppError(e);
    }
  }

  /// GET /users/me/followers
  Future<PaginationResponse<User>> getMyFollowers({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/users/me/followers',
        queryParameters: {'page': page, 'perPage': perPage},
      );
      return _parsePagination(response.data!, User.fromJson);
    } catch (e) {
      throw mapToAppError(e);
    }
  }

  /// GET /users/me/followed-users
  Future<PaginationResponse<User>> getFollowedUsers({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/users/me/followed-users',
        queryParameters: {'page': page, 'perPage': perPage},
      );
      return _parsePagination(response.data!, User.fromJson);
    } catch (e) {
      throw mapToAppError(e);
    }
  }
}
