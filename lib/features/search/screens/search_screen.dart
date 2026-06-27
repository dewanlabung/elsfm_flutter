import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elsfm/features/search/providers/search_provider.dart';
import 'package:elsfm/features/search/widgets/search_results_list.dart';
import 'package:elsfm/features/search/widgets/trending_section.dart';

/// Search screen with real-time search and trending content
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Load trending on init
    Future.microtask(() {
      ref.read(debouncedSearchProvider.notifier).getTrending();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      ref.read(debouncedSearchProvider.notifier).getTrending();
      return;
    }

    // Debounce search (400ms delay)
    Future.delayed(const Duration(milliseconds: 400), () {
      if (_searchController.text == query) {
        ref.read(debouncedSearchProvider.notifier).search(query);
      }
    });
  }

  void _onSearchSubmitted(String query) {
    if (query.isNotEmpty) {
      ref.read(recentSearchesProvider.notifier).addSearch(query);
      ref.read(debouncedSearchProvider.notifier).search(query);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(debouncedSearchProvider.notifier).getTrending();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(debouncedSearchProvider);
    final recentSearches = ref.watch(recentSearchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search input field
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              controller: _searchController,
              focusNode: _searchFocus,
              hintText: 'Songs, artists, playlists...',
              onChanged: _onSearchChanged,
              onSubmitted: _onSearchSubmitted,
              leading: const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Icon(Icons.search),
              ),
              trailing: _searchController.text.isNotEmpty
                  ? [
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      ),
                    ]
                  : [],
            ),
          ),
          // Content
          Expanded(
            child: searchState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 16),
                    Text('Search error: ${error.toString()}'),
                  ],
                ),
              ),
              data: (state) {
                // Show search results
                if (state.hasResults) {
                  return SearchResultsList(state: state);
                }

                // Show recent searches if query is empty
                if (state.query.isEmpty && recentSearches.isNotEmpty) {
                  return RecentSearchList(searches: recentSearches);
                }

                // Show trending
                if (state.hasTrending) {
                  return TrendingSection(trending: state.trending!);
                }

                // Empty state
                return const SearchEmptyState();
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays the list of recent searches with clear controls.
class RecentSearchList extends ConsumerWidget {
  final List<String> searches;

  const RecentSearchList({super.key, required this.searches});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Searches',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: () {
                ref.read(recentSearchesProvider.notifier).clearAll();
              },
              child: const Text('Clear all'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...searches.map((search) {
          return ListTile(
            leading: const Icon(Icons.history),
            title: Text(search),
            trailing: IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () {
                ref.read(recentSearchesProvider.notifier).removeSearch(search);
              },
            ),
            onTap: () {
              ref.read(recentSearchesProvider.notifier).addSearch(search);
              ref.read(debouncedSearchProvider.notifier).search(search);
            },
          );
        }),
      ],
    );
  }
}

/// Placeholder shown when there are no results, trending content, or recent searches.
class SearchEmptyState extends StatelessWidget {
  const SearchEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          const Text(
            'Search songs, artists, playlists',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for your favorite music',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}
