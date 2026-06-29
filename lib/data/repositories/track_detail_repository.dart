import 'package:dio/dio.dart';
import '../models/track.dart';
import '../models/comment.dart';
import '../models/lyric.dart';
import '../models/genre.dart';
import '../models/tag.dart';
import '../models/album.dart';
import '../models/backend_response.dart';
import '../models/app_error.dart';
import '../services/hive_service.dart';

/// Extends track data with swagger endpoints not covered by [TrackRepository]:
///   GET /tracks/{id}?with=tags,genres,artists,album  (enriched detail)
///   GET /tracks/{id}/comments
///   GET /tracks/{id}/lyrics
///
/// [TrackRepository] covers list + basic detail; this repository adds the
/// relations and sub-resources.
class TrackDetailRepository {
  final Dio dio;

  TrackDetailRepository({required this.dio});

  /// GET /tracks/{id}?with=album,genres,tags
  Future<TrackDetail> getTrackDetail(
    int id, {
    String withRelations = 'album,genres,tags',
  }) async {
    final cacheKey = 'track_detail_${id}_$withRelations';
    final cache = HiveService.getTrackCache();
    final cached = cache.get(cacheKey);
    if (cached != null) {
      return TrackDetail.fromJson(cached);
    }

    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/tracks/$id',
        queryParameters: {'with': withRelations},
      );
      final body = response.data!;
      final trackJson = body['track'] as Map<String, dynamic>? ?? body;
      await cache.put(cacheKey, trackJson);
      return TrackDetail.fromJson(trackJson);
    } catch (e) {
      throw mapToAppError(e);
    }
  }

  /// GET /tracks/{id}/comments
  Future<PaginationResponse<Comment>> getTrackComments(
    int id, {
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/tracks/$id/comments',
        queryParameters: {'page': page, 'perPage': perPage},
      );
      final body = response.data!;
      final inner = body.containsKey('pagination')
          ? body['pagination'] as Map<String, dynamic>
          : body;
      final items = ((inner['data'] ?? []) as List)
          .map((e) => Comment.fromJson(e as Map<String, dynamic>))
          .toList();
      return PaginationResponse(
        data: items,
        currentPage: (inner['current_page'] as num?)?.toInt() ?? 1,
        lastPage: (inner['last_page'] as num?)?.toInt() ?? 1,
        total: (inner['total'] as num?)?.toInt() ?? 0,
        perPage: (inner['per_page'] as num?)?.toInt() ?? perPage,
      );
    } catch (e) {
      throw mapToAppError(e);
    }
  }

  /// GET /tracks/{id}/lyrics
  Future<Lyric?> getTrackLyrics(int id) async {
    final cacheKey = 'track_lyric_$id';
    final cache = HiveService.getTrackCache();
    final cached = cache.get(cacheKey);
    if (cached != null) {
      return Lyric.fromJson(cached);
    }

    try {
      final response = await dio.get<Map<String, dynamic>>('/tracks/$id/lyrics');
      final body = response.data!;
      final lyricJson = body['lyric'] as Map<String, dynamic>?;
      if (lyricJson == null) return null;
      await cache.put(cacheKey, lyricJson);
      return Lyric.fromJson(lyricJson);
    } catch (e) {
      throw mapToAppError(e);
    }
  }
}

/// Extended track with optional album, genres, and tags from the detail endpoint.
class TrackDetail {
  final Track track;
  final Album? album;
  final List<Genre>? genres;
  final List<Tag>? tags;

  TrackDetail({
    required this.track,
    this.album,
    this.genres,
    this.tags,
  });

  factory TrackDetail.fromJson(Map<String, dynamic> json) {
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

    return TrackDetail(
      track: Track.fromJson(json),
      album: json['album'] != null
          ? Album.fromJson(json['album'] as Map<String, dynamic>)
          : null,
      genres: _parseList('genres', Genre.fromJson),
      tags: _parseList('tags', Tag.fromJson),
    );
  }

  Map<String, dynamic> toJson() => {
        ...track.toJson(),
        if (album != null) 'album': album!.toJson(),
        if (genres != null) 'genres': genres!.map((g) => g.toJson()).toList(),
        if (tags != null) 'tags': tags!.map((t) => t.toJson()).toList(),
      };
}
