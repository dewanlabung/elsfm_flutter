import 'package:flutter_test/flutter_test.dart';
import 'package:elsfm/features/search/services/search_service.dart';
import 'package:elsfm/features/search/models/search_state.dart';

void main() {
  group('SearchState', () {
    test('SearchState.initial returns empty state', () {
      final state = SearchState.initial();

      expect(state.query, isEmpty);
      expect(state.results, isNull);
      expect(state.trending, isNull);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isEmpty, isTrue);
    });

    test('SearchState.copyWith updates fields', () {
      final state1 = SearchState.initial();
      final state2 = state1.copyWith(query: 'test', isLoading: true);

      expect(state1.query, isEmpty);
      expect(state2.query, equals('test'));
      expect(state2.isLoading, isTrue);
    });

    test('SearchResults empty check works', () {
      final state = SearchState.initial();

      expect(state.isEmpty, isTrue);
      expect(state.hasResults, isFalse);
    });
  });

  group('SearchService', () {
    test('Search with empty query returns empty results', () async {
      // This is a unit test for the logic, not the API
      final service = SearchService(repository: _MockSearchRepository());
      
      final results = await service.search(query: '');
      
      expect(results.isEmpty, isTrue);
    });

    test('SearchException message is preserved', () {
      const exception = SearchException('Test error');
      
      expect(exception.message, equals('Test error'));
      expect(exception.toString(), contains('SearchException'));
    });

    test('TrendingResults empty check works', () {
      final trending = TrendingResults(
        songs: [],
        artists: [],
        type: 'songs',
        period: 'week',
      );
      
      expect(trending.isEmpty, isTrue);
      expect(trending.isNotEmpty, isFalse);
    });
  });
}

class _MockSearchRepository {
  Future<Map<String, dynamic>> search({
    required String query,
    int page = 1,
    int limit = 20,
    List<String>? filters,
  }) async {
    return {
      'songs': [],
      'artists': [],
      'playlists': [],
      'page': page,
      'total': 0,
    };
  }
}
