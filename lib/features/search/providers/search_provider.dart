import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elsfm/data/providers/http_client_provider.dart';
import 'package:elsfm/data/repositories/search_repository.dart';
import '../services/search_service.dart';
import '../models/search_state.dart';

/// Search repository provider
final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final dio = ref.watch(dioProvider).requireValue;
  return SearchRepository(dio: dio);
});

/// Search service provider
final searchServiceProvider = Provider<SearchService>((ref) {
  final repository = ref.watch(searchRepositoryProvider);
  return SearchService(repository: repository);
});

/// Search query state provider
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Debounced search state notifier
class DebouncedSearchNotifier extends AsyncNotifier<SearchState> {
  SearchService? _searchService;

  @override
  Future<SearchState> build() async {
    return SearchState.initial();
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = const AsyncValue.data(SearchState.initial());
      return;
    }

    state = const AsyncValue.loading();

    try {
      _searchService ??= ref.read(searchServiceProvider);
      final results = await _searchService!.search(query: query);

      state = AsyncValue.data(
        SearchState(
          query: query,
          results: results,
          isLoading: false,
          error: null,
        ),
      );
    } catch (e) {
      state = AsyncValue.data(
        SearchState(
          query: query,
          results: null,
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> getTrending() async {
    state = const AsyncValue.loading();

    try {
      _searchService ??= ref.read(searchServiceProvider);
      final trending = await _searchService!.getTrending();

      state = AsyncValue.data(
        SearchState(
          query: '',
          trending: trending,
          isLoading: false,
          error: null,
        ),
      );
    } catch (e) {
      state = AsyncValue.data(
        SearchState(
          query: '',
          trending: null,
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  void clear() {
    state = const AsyncValue.data(SearchState.initial());
  }
}

/// Debounced search state provider
final debouncedSearchProvider = AsyncNotifierProvider<DebouncedSearchNotifier, SearchState>(
  () => DebouncedSearchNotifier(),
);

/// Recently searched queries provider (local storage)
final recentSearchesProvider = StateNotifierProvider<RecentSearchesNotifier, List<String>>(
  (ref) => RecentSearchesNotifier([]),
);

class RecentSearchesNotifier extends StateNotifier<List<String>> {
  RecentSearchesNotifier(super.state);

  void addSearch(String query) {
    if (query.isEmpty) return;

    // Remove if exists, then add to front
    state = [
      query,
      ...state.where((q) => q != query).take(9),
    ];
  }

  void clearAll() {
    state = [];
  }

  void removeSearch(String query) {
    state = state.where((q) => q != query).toList();
  }
}
