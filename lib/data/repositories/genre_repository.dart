import 'package:dio/dio.dart';
import '../models/genre.dart';
import '../models/backend_response.dart';
import '../models/app_error.dart';
import '../services/hive_service.dart';

/// Repository for genre data. Covers:
///   GET /genres
class GenreRepository {
  final Dio dio;

  GenreRepository({required this.dio});

  /// GET /genres — returns a paginated list of all genres.
  Future<PaginationResponse<Genre>> getGenres({
    int page = 1,
    int perPage = 50,
  }) async {
    const cacheKey = 'genres_all';
    final cache = HiveService.getGenreCache();

    if (page == 1) {
      final cachedList = cache.getList(cacheKey);
      if (cachedList != null) {
        return PaginationResponse(
          data: cachedList.map(Genre.fromJson).toList(),
          currentPage: 1,
          lastPage: 1,
          total: cachedList.length,
          perPage: perPage,
        );
      }
    }

    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/genres',
        queryParameters: {'page': page, 'perPage': perPage},
      );
      final body = response.data!;
      final inner = body.containsKey('pagination')
          ? body['pagination'] as Map<String, dynamic>
          : body;
      final items = ((inner['data'] ?? []) as List)
          .map((e) => Genre.fromJson(e as Map<String, dynamic>))
          .toList();

      if (page == 1) {
        await cache.putList(
          cacheKey,
          items.map((g) => g.toJson()).toList(),
        );
      }

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
}
