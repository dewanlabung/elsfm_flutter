import 'package:dio/dio.dart';
import '../models/artist.dart';
import '../models/album.dart';
import '../models/track.dart';
import '../models/artist_profile.dart';
import '../models/genre.dart';
import '../models/user.dart';
import '../models/backend_response.dart';
import '../models/app_error.dart';
import '../services/hive_service.dart';

/// Repository for artist data. Covers all artist-scoped swagger endpoints:
///   GET /artists/{id}
///   GET /artists/{id}/tracks
///   GET /artists/{id}/albums
///   GET /artists/{id}/followers
class ArtistRepository {
  final Dio dio;

  ArtistRepository({required this.dio});

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

  /// GET /artists/{id}?with=similar,genres,albums,topTracks
  ///
  /// Returns the artist augmented with optional relations. Pass [withRelations]
  /// as a comma-separated string such as `'albums,genres,topTracks,similar'`.
  Future<ArtistDetail> getArtist(
    int id, {
    String? withRelations,
  }) async {
    final cacheKey = 'artist_${id}_${withRelations ?? 'base'}';
    final cache = HiveService.getArtistCache();
    final cached = cache.get(cacheKey);
    if (cached != null) {
      return ArtistDetail.fromJson(cached);
    }

    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/artists/$id',
        queryParameters: {
          if (withRelations != null) 'with': withRelations,
        },
      );
      final body = response.data!;
      final artistJson = body['artist'] as Map<String, dynamic>? ?? body;
      await cache.put(cacheKey, artistJson);
      return ArtistDetail.fromJson(artistJson);
    } catch (e) {
      throw mapToAppError(e);
    }
  }

  /// GET /artists/{id}/tracks
  Future<PaginationResponse<Track>> getArtistTracks(
    int id, {
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/artists/$id/tracks',
        queryParameters: {'page': page, 'perPage': perPage},
      );
      return _parsePagination(response.data!, Track.fromJson);
    } catch (e) {
      throw mapToAppError(e);
    }
  }

  /// GET /artists/{id}/albums
  Future<PaginationResponse<Album>> getArtistAlbums(
    int id, {
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/artists/$id/albums',
        queryParameters: {'page': page, 'perPage': perPage},
      );
      return _parsePagination(response.data!, Album.fromJson);
    } catch (e) {
      throw mapToAppError(e);
    }
  }

  /// GET /artists/{id}/followers
  Future<PaginationResponse<User>> getArtistFollowers(
    int id, {
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/artists/$id/followers',
        queryParameters: {'page': page, 'perPage': perPage},
      );
      return _parsePagination(response.data!, User.fromJson);
    } catch (e) {
      throw mapToAppError(e);
    }
  }

  /// Invalidate cached artist data.
  Future<void> invalidateArtist(int id) async {
    final cache = HiveService.getArtistCache();
    for (final suffix in ['base', 'albums,genres,topTracks,similar']) {
      await cache.invalidate('artist_${id}_$suffix');
    }
  }
}

/// Extended artist object returned by GET /artists/{id}.
/// Wraps the base [Artist] and exposes optional loaded relations.
class ArtistDetail {
  final Artist artist;
  final List<Album>? albums;
  final List<Artist>? similar;
  final List<Track>? topTracks;
  final List<Genre>? genres;
  final ArtistProfile? profile;
  final List<ArtistProfileImage>? profileImages;
  final List<ArtistProfileLink>? links;

  ArtistDetail({
    required this.artist,
    this.albums,
    this.similar,
    this.topTracks,
    this.genres,
    this.profile,
    this.profileImages,
    this.links,
  });

  factory ArtistDetail.fromJson(Map<String, dynamic> json) {
    List<T>? _parseList<T>(
      String key,
      T Function(Map<String, dynamic>) fromJson,
    ) {
      final raw = json[key];
      if (raw == null) return null;
      // Albums come wrapped in pagination when loaded via ?with=albums
      if (raw is Map<String, dynamic>) {
        final data = raw['data'] as List?;
        if (data != null) {
          return data.map((e) => fromJson(e as Map<String, dynamic>)).toList();
        }
        return null;
      }
      if (raw is List) {
        return raw.map((e) => fromJson(e as Map<String, dynamic>)).toList();
      }
      return null;
    }

    return ArtistDetail(
      artist: Artist.fromJson(json),
      albums: _parseList('albums', Album.fromJson),
      similar: _parseList('similar', Artist.fromJson),
      topTracks: _parseList('top_tracks', Track.fromJson),
      genres: _parseList('genres', Genre.fromJson),
      profile: json['profile'] != null
          ? ArtistProfile.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
      profileImages: _parseList('profile_images', ArtistProfileImage.fromJson),
      links: _parseList('links', ArtistProfileLink.fromJson),
    );
  }

  Map<String, dynamic> toJson() => {
        ...artist.toJson(),
        if (albums != null) 'albums': albums!.map((a) => a.toJson()).toList(),
        if (similar != null) 'similar': similar!.map((a) => a.toJson()).toList(),
        if (topTracks != null) 'top_tracks': topTracks!.map((t) => t.toJson()).toList(),
        if (genres != null) 'genres': genres!.map((g) => g.toJson()).toList(),
        if (profile != null) 'profile': profile!.toJson(),
        if (profileImages != null)
          'profile_images': profileImages!.map((i) => i.toJson()).toList(),
        if (links != null) 'links': links!.map((l) => l.toJson()).toList(),
      };
}
