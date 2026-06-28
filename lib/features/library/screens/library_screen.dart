import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elsfm/features/auth/providers/auth_notifier.dart';
import 'package:elsfm/features/auth/models/auth_state.dart';
import 'package:elsfm/features/player/providers/player_notifier.dart';
import '../providers/library_provider.dart';

/// User library screen (favorites + history)
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    // Check if user is authenticated
    if (authState.state != AuthState.authenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Library'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Please log in to access your library',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamed('/login'),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

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
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to load liked songs'),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(ref.context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      data: (favorites) {
        if (favorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
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
              trailing: const Icon(Icons.play_arrow),
              onTap: () {
                // Play track via player provider
                ref.read(playerNotifierProvider.notifier).playTrack(track);
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
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to load play history'),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(ref.context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      data: (history) {
        if (history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history, size: 64, color: Colors.grey),
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
              trailing: const Icon(Icons.play_arrow),
              onTap: () {
                // Play track via player provider
                ref.read(playerNotifierProvider.notifier).playTrack(track);
              },
            );
          },
        );
      },
    );
  }
}
