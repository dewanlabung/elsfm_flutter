import 'package:dio/dio.dart';
import '../models/track.dart';
import '../models/backend_response.dart';
import '../models/app_error.dart';
import '../services/hive_service.dart';

/// Repository for track data with Hive read-through cache.
class TrackRepository {
  final Dio dio;

  TrackRepository({required this.dio});

  /// Fetch a single track by [id].
  ///
  /// Returns the cached value (up to 30 min old) if present; otherwise fetches
  /// from the network and writes the result to the cache.
  Future<Track> getTrack(int id) async {
    final cache = HiveService.getTrackCache();
    final cached = cache.get('track_$id');
    if (cached != null) {
      return Track.fromJson(cached);
    }

    try {
      final response = await dio.get<Map<String, dynamic>>('/tracks/$id');
      final data = response.data!;
      await cache.put('track_$id', data);
      return Track.fromJson(data);
    } catch (e) {
      throw mapToAppError(e);
    }
  }

  /// Fetch a paginated list of tracks ordered by [orderBy].
  ///
  /// Only page 1 is cached (the "top tracks" result that is shown on home).
  Future<PaginationResponse<Track>> getTracks({
    int page = 1,
    int perPage = 20,
    String orderBy = 'plays',
    String orderDir = 'desc',
  }) async {
    final cacheKey = 'tracks_p${page}_${orderBy}_$orderDir';
    final cache = HiveService.getTrackCache();

    if (page == 1) {
      final cachedList = cache.getList(cacheKey);
      if (cachedList != null) {
        return PaginationResponse(
          data: cachedList.map(Track.fromJson).toList(),
          currentPage: 1,
          lastPage: 1,
          total: cachedList.length,
          perPage: perPage,
        );
      }
    }

    try {
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
      final inner = data.containsKey('pagination')
          ? data['pagination'] as Map<String, dynamic>
          : data;
      final items = ((inner['data'] ?? []) as List)
          .map((e) => Track.fromJson(e as Map<String, dynamic>))
          .toList();

      if (page == 1) {
        await cache.putList(
          cacheKey,
          items.map((t) => t.toJson()).toList(),
        );
      }

      return PaginationResponse(
        data: items,
        currentPage: inner['current_page'] as int? ?? 1,
        lastPage: inner['last_page'] as int? ?? 1,
        total: inner['total'] as int? ?? 0,
        perPage: inner['per_page'] as int? ?? perPage,
      );
    } catch (e) {
      throw mapToAppError(e);
    }
  }

  /// Invalidate the cache for a specific track.
  Future<void> invalidateTrack(int id) async {
    final cache = HiveService.getTrackCache();
    await cache.invalidate('track_$id');
  }
}
