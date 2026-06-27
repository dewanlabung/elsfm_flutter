import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/library_provider.dart';

/// User library screen (favorites + history)
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Library'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Liked Songs'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFavoritesTab(ref),
            _buildHistoryTab(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesTab(WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);

    return favoritesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (favorites) {
        if (favorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite_border, size: 64),
                const SizedBox(height: 16),
                const Text('No liked songs yet'),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final track = favorites[index];
            return ListTile(
              leading: const Icon(Icons.favorite, color: Colors.red),
              title: Text(track.name),
              subtitle: Text(track.artists.map((a) => a.name).join(', ')),
              onTap: () {
                // Play track
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryTab(WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (history) {
        if (history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history, size: 64),
                const SizedBox(height: 16),
                const Text('No play history'),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: history.length,
          itemBuilder: (context, index) {
            final track = history[index];
            return ListTile(
              leading: Text('${index + 1}'),
              title: Text(track.name),
              subtitle: Text(track.artists.map((a) => a.name).join(', ')),
              onTap: () {
                // Play track
              },
            );
          },
        );
      },
    );
  }
}
