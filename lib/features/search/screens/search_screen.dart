import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/search_provider.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
              },
              decoration: InputDecoration(
                hintText: 'Search tracks, artists, albums...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: query.isEmpty
                ? const Center(
                    child: Text('Enter a search term'),
                  )
                : resultsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (err, st) => Center(
                      child: Text('Error: $err'),
                    ),
                    data: (results) {
                      if (results.isEmpty) {
                        return const Center(
                          child: Text('No results found'),
                        );
                      }

                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (results['tracks'] != null &&
                                (results['tracks'] as List).isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tracks',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    for (final track in results['tracks'])
                                      ListTile(
                                        title: Text(track['name'] ?? 'Unknown'),
                                        subtitle: Text(
                                          track['artists']?[0]?['name'] ??
                                              'Unknown artist',
                                        ),
                                        leading:
                                            const Icon(Icons.music_note),
                                      ),
                                  ],
                                ),
                              ),
                            if (results['artists'] != null &&
                                (results['artists'] as List).isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Artists',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    for (final artist in results['artists'])
                                      ListTile(
                                        title:
                                            Text(artist['name'] ?? 'Unknown'),
                                        leading: const Icon(Icons.person),
                                      ),
                                  ],
                                ),
                              ),
                            if (results['albums'] != null &&
                                (results['albums'] as List).isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Albums',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    for (final album in results['albums'])
                                      ListTile(
                                        title:
                                            Text(album['name'] ?? 'Unknown'),
                                        subtitle: Text(
                                          album['artists']?[0]?['name'] ??
                                              'Unknown artist',
                                        ),
                                        leading: const Icon(Icons.album),
                                      ),
                                  ],
                                ),
                              ),
                            if (results['playlists'] != null &&
                                (results['playlists'] as List).isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Playlists',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    for (final playlist
                                        in results['playlists'])
                                      ListTile(
                                        title: Text(
                                            playlist['name'] ?? 'Unknown'),
                                        leading: const Icon(
                                            Icons.playlist_play),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
