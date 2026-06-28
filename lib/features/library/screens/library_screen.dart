import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elsfm/features/auth/providers/auth_notifier.dart';
import 'package:elsfm/features/auth/models/auth_state.dart';
import 'package:elsfm/features/player/providers/player_notifier.dart';
import '../providers/library_provider.dart';

/// User library screen with categories (Songs, Playlists, Albums, Artists, History)
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    if (authState.state != AuthState.authenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your library')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Please log in to access your library', textAlign: TextAlign.center),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Your library')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LibraryCategoryTile(
              icon: Icons.music_note,
              title: 'Songs',
              subtitle: 'Liked songs',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _SongsScreen())),
            ),
            const SizedBox(height: 12),
            _LibraryCategoryTile(
              icon: Icons.playlist_play,
              title: 'Playlists',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Playlists coming soon'))),
            ),
            const SizedBox(height: 12),
            _LibraryCategoryTile(
              icon: Icons.album,
              title: 'Albums',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Albums coming soon'))),
            ),
            const SizedBox(height: 12),
            _LibraryCategoryTile(
              icon: Icons.person,
              title: 'Artists',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Artists coming soon'))),
            ),
            const SizedBox(height: 12),
            _LibraryCategoryTile(
              icon: Icons.history,
              title: 'Play history',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _HistoryScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryCategoryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _LibraryCategoryTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _SongsScreen extends ConsumerWidget {
  const _SongsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Songs')),
      body: favoritesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (favorites) {
          if (favorites.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No liked songs yet'),
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
                onTap: () => ref.read(playerProvider.notifier).playTrack(track),
              );
            },
          );
        },
      ),
    );
  }
}

class _HistoryScreen extends ConsumerWidget {
  const _HistoryScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Play history')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (history) {
          if (history.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No play history'),
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
                onTap: () => ref.read(playerProvider.notifier).playTrack(track),
              );
            },
          );
        },
      ),
    );
  }
}
