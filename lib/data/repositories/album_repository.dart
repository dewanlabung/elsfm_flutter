import 'package:dio/dio.dart';
import '../models/album.dart';
import '../models/genre.dart';
import '../models/tag.dart';
import '../models/app_error.dart';
import '../services/hive_service.dart';

/// Repository for album data. Covers:
///   GET /albums/{id}?with=tags,genres,artists,tracks
class AlbumRepository {
  final Dio dio;

  AlbumRepository({required this.dio});

  /// GET /albums/{id}
  ///
  /// [withRelations] is a comma-separated string: `'tags,genres,artists,tracks'`.
  Future<AlbumDetail> getAlbum(
    int id, {
    String? withRelations,
  }) async {
    final cacheKey = 'album_${id}_${withRelations ?? 'base'}';
    final cache = HiveService.getAlbumCache();
    final cached = cache.get(cacheKey);
    if (cached != null) {
      return AlbumDetail.fromJson(cached);
    }

    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/albums/$id',
        queryParameters: {
          if (withRelations != null) 'with': withRelations,
        },
      );
      final body = response.data!;
      final albumJson = body['album'] as Map<String, dynamic>? ?? body;
      await cache.put(cacheKey, albumJson);
      return AlbumDetail.fromJson(albumJson);
    } catch (e) {
      throw mapToAppError(e);
    }
  }

  /// Invalidate cached album data.
  Future<void> invalidateAlbum(int id) async {
    final cache = HiveService.getAlbumCache();
    for (final suffix in ['base', 'tags,genres,artists,tracks']) {
      await cache.invalidate('album_${id}_$suffix');
    }
  }
}

/// Extended album returned by GET /albums/{id}.
class AlbumDetail {
  final Album album;
  final List<Genre>? genres;
  final List<Tag>? tags;

  AlbumDetail({required this.album, this.genres, this.tags});

  factory AlbumDetail.fromJson(Map<String, dynamic> json) {
    List<T>? _parseList<T>(
      String key,
      T Function(Map<String, dynamic>) fromJson,
    ) {
      final raw = json[key];
      if (raw == null) return null;
      if (raw is List) {
        return raw.map((e) => fromJson(e as Map<String, dynamic>)).toList();
      }
      return null;
    }

    return AlbumDetail(
      album: Album.fromJson(json),
      genres: _parseList('genres', Genre.fromJson),
      tags: _parseList('tags', Tag.fromJson),
    );
  }

  Map<String, dynamic> toJson() => {
        ...album.toJson(),
        if (genres != null) 'genres': genres!.map((g) => g.toJson()).toList(),
        if (tags != null) 'tags': tags!.map((t) => t.toJson()).toList(),
      };
}
