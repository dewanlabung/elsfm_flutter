import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elsfm/data/repositories/search_repository.dart';
import 'package:elsfm/data/models/track.dart';
import 'package:elsfm/data/models/artist.dart';
import 'package:elsfm/data/models/playlist.dart';
import '../models/search_state.dart';

/// Search service using SearchRepository with debouncing
class SearchService {
  final SearchRepository repository;

  SearchService({required this.repository});

  /// Search across all content with debouncing support
  Future<SearchResults> search({
    required String query,
    int page = 1,
    int limit = 20,
    List<String>? filters,
  }) async {
    if (query.isEmpty) {
      return SearchResults.empty();
    }

    try {
      final result = await repository.search(
        query: query,
        page: page,
        limit: limit,
        filters: filters,
      );

      return SearchResults(
        songs: result['songs'] as List<Track>? ?? [],
        artists: result['artists'] as List<Artist>? ?? [],
        playlists: result['playlists'] as List<Playlist>? ?? [],
        page: (result['page'] as num?)?.toInt() ?? page,
        total: (result['total'] as num?)?.toInt() ?? 0,
        query: query,
      );
    } catch (e) {
      throw SearchException('Search failed: $e');
    }
  }

  /// Search only songs
  Future<List<Track>> searchSongs({
    int? artistId,
    int? albumId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      return await repository.searchSongs(
        artistId: artistId,
        albumId: albumId,
        page: page,
        limit: limit,
      );
    } catch (e) {
      throw SearchException('Song search failed: $e');
    }
  }

  /// Get trending content
  Future<TrendingResults> getTrending({
    String type = 'songs',
    String period = 'week',
    int limit = 50,
  }) async {
    try {
      final result = await repository.getTrending(
        type: type,
        period: period,
        limit: limit,
      );

      return TrendingResults(
        songs: result['songs'] as List<Track>? ?? [],
        artists: result['artists'] as List<Artist>? ?? [],
        type: type,
        period: period,
      );
    } catch (e) {
      throw SearchException('Trending fetch failed: $e');
    }
  }
}

/// Search exception
class SearchException implements Exception {
  final String message;

  SearchException(this.message);

  @override
  String toString() => 'SearchException: $message';
}
