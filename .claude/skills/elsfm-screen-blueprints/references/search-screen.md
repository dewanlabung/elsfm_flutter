# Search Screen

Real-time search with 400 ms debounce, recent-searches list, and trending
fallback. Mirrors `lib/features/search/screens/search_screen.dart` and
`lib/features/search/providers/search_provider.dart`.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:elsfm/features/search/providers/search_provider.dart';
import 'package:elsfm/features/search/models/search_state.dart';
import 'package:elsfm/features/search/widgets/search_results_list.dart';
import 'package:elsfm/features/search/widgets/trending_section.dart';
import 'package:elsfm/features/player/providers/player_notifier.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Load trending content on first open.
    Future.microtask(
      () => ref.read(debouncedSearchProvider.notifier).getTrending(),
    );
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  // Rebuild the clear button when the text field changes.
  void _onControllerChanged() => setState(() {});

  void _onChanged(String query) {
    if (query.isEmpty) {
      ref.read(debouncedSearchProvider.notifier).getTrending();
      return;
    }
    // 400 ms debounce — only fire if the value hasn't changed by then.
    Future.delayed(const Duration(milliseconds: 400), () {
      if (_controller.text == query && mounted) {
        ref.read(debouncedSearchProvider.notifier).search(query);
      }
    });
  }

  void _onSubmitted(String query) {
    if (query.trim().isEmpty) return;
    ref.read(recentSearchesProvider.notifier).addSearch(query.trim());
    ref.read(debouncedSearchProvider.notifier).search(query.trim());
    _focus.unfocus();
  }

  void _clear() {
    _controller.clear();
    ref.read(debouncedSearchProvider.notifier).getTrending();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync  = ref.watch(debouncedSearchProvider);
    final recent       = ref.watch(recentSearchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Search field ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SearchBar(
              controller: _controller,
              focusNode: _focus,
              hintText: 'Songs, artists, albums…',
              elevation: const WidgetStatePropertyAll(1),
              onChanged: _onChanged,
              onSubmitted: _onSubmitted,
              leading: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.search),
              ),
              trailing: _controller.text.isNotEmpty
                  ? [
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clear,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 8),

          // ── Content area ────────────────────────────────────────────────
          Expanded(
            child: searchAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => _SearchErrorState(
                error: err.toString(),
                onRetry: () =>
                    ref.read(debouncedSearchProvider.notifier).getTrending(),
              ),
              data: (state) => _SearchContent(
                state: state,
                recent: recent,
                onRecentTap: (q) {
                  _controller.text = q;
                  _controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: q.length),
                  );
                  ref.read(debouncedSearchProvider.notifier).search(q);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Content switcher
// ---------------------------------------------------------------------------

class _SearchContent extends StatelessWidget {
  final SearchState state;
  final List<String> recent;
  final ValueChanged<String> onRecentTap;

  const _SearchContent({
    required this.state,
    required this.recent,
    required this.onRecentTap,
  });

  @override
  Widget build(BuildContext context) {
    // Priority: results > recent searches > trending > empty prompt.
    if (state.hasResults) {
      return SearchResultsList(state: state);
    }
    if (state.query.isEmpty && recent.isNotEmpty) {
      return _RecentSearchList(searches: recent, onTap: onRecentTap);
    }
    if (state.hasTrending) {
      return TrendingSection(trending: state.trending!);
    }
    return const _EmptyPrompt();
  }
}

// ---------------------------------------------------------------------------
// Recent searches
// ---------------------------------------------------------------------------

class _RecentSearchList extends ConsumerWidget {
  final List<String> searches;
  final ValueChanged<String> onTap;

  const _RecentSearchList({required this.searches, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Searches',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(recentSearchesProvider.notifier).clearAll(),
              child: const Text('Clear all'),
            ),
          ],
        ),
        ...searches.map(
          (q) => ListTile(
            leading: const Icon(Icons.history, size: 20),
            title: Text(q),
            contentPadding: EdgeInsets.zero,
            trailing: IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () =>
                  ref.read(recentSearchesProvider.notifier).removeSearch(q),
            ),
            onTap: () => onTap(q),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

class _SearchErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _SearchErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Search unavailable'),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty prompt
// ---------------------------------------------------------------------------

class _EmptyPrompt extends StatelessWidget {
  const _EmptyPrompt();

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
            'Try searching for your favourite music',
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
```

## Providers Referenced

| Provider | File | Returns |
|----------|------|---------|
| `debouncedSearchProvider` | `features/search/providers/search_provider.dart` | `AsyncValue<SearchState>` |
| `recentSearchesProvider` | `features/search/providers/search_provider.dart` | `List<String>` |
| `playerProvider` | `features/player/providers/player_notifier.dart` | `PlayerState` |

## GoRouter Entry

```dart
GoRoute(
  path: '/search',
  builder: (context, state) => const SearchScreen(),
),
```

## SearchState Shape

```dart
class SearchState {
  final String query;
  final SearchResults? results;
  final TrendingData? trending;
  final bool isLoading;
  final String? error;

  bool get hasResults => results != null && results!.tracks.isNotEmpty;
  bool get hasTrending => trending != null;

  factory SearchState.initial() => SearchState(query: '', isLoading: false);
}
```

## Debounce Pattern

The debounce is implemented inline with `Future.delayed`. If you need a
cancellable approach, use a `Timer`:

```dart
Timer? _debounce;

void _onChanged(String q) {
  _debounce?.cancel();
  if (q.isEmpty) {
    ref.read(debouncedSearchProvider.notifier).getTrending();
    return;
  }
  _debounce = Timer(const Duration(milliseconds: 400), () {
    ref.read(debouncedSearchProvider.notifier).search(q);
  });
}

@override
void dispose() {
  _debounce?.cancel();
  // ...
}
```

## Adding Filters (Genre, Duration)

```dart
// 1. Extend SearchState with a FilterOptions field.
// 2. Add a FilterChipRow widget below the SearchBar.
// 3. Pass filters into DebouncedSearchNotifier.search().

FilledButton.tonalIcon(
  onPressed: () => _showFilterSheet(context, ref),
  icon: const Icon(Icons.tune, size: 18),
  label: const Text('Filters'),
),
```
