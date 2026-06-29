import 'package:dio/dio.dart';
import '../models/track.dart';
import '../models/album.dart';
import '../models/backend_response.dart';
import '../models/app_error.dart';

/// Repository for tag-scoped data. Covers:
///   GET /tags/{name}/tracks
///   GET /tags/{name}/albums
class TagRepository {
  final Dio dio;

  TagRepository({required this.dio});

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

  /// GET /tags/{name}/tracks
  Future<PaginationResponse<Track>> getTagTracks(
    String tagName, {
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/tags/$tagName/tracks',
        queryParameters: {'page': page, 'perPage': perPage},
      );
      return _parsePagination(response.data!, Track.fromJson);
    } catch (e) {
      throw mapToAppError(e);
    }
  }

  /// GET /tags/{name}/albums
  Future<PaginationResponse<Album>> getTagAlbums(
    String tagName, {
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/tags/$tagName/albums',
        queryParameters: {'page': page, 'perPage': perPage},
      );
      return _parsePagination(response.data!, Album.fromJson);
    } catch (e) {
      throw mapToAppError(e);
    }
  }
}
