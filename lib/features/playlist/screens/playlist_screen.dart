import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/playlist_provider.dart';

class PlaylistScreen extends ConsumerStatefulWidget {
  final int playlistId;

  const PlaylistScreen({
    super.key,
    required this.playlistId,
  });

  @override
  ConsumerState<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends ConsumerState<PlaylistScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(selectedPlaylistIdProvider.notifier).state = widget.playlistId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final playlistAsync = ref.watch(playlistProvider);
    final tracksAsync = ref.watch(playlistTracksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Playlist')),
      body: playlistAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
        data: (playlist) => CustomScrollView(
          slivers: [
            // Playlist header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.playlist_play, size: 100, color: Color(0xFF1DB954)),
                    const SizedBox(height: 16),
                    Text(
                      playlist['name'] ?? 'Unknown',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    if (playlist['description']?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 8),
                      Text(
                        playlist['description'] ?? '',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (playlist['owner'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'by ${playlist['owner']['name'] ?? 'Unknown'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1DB954),
                        ),
                        child: const Text('Play All'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Tracks list
            tracksAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, st) => SliverToBoxAdapter(
                child: Center(child: Text('Error: $err')),
              ),
              data: (tracks) => SliverList.builder(
                itemCount: tracks.length,
                itemBuilder: (context, index) {
                  final track = tracks[index];
                  return ListTile(
                    leading: Text('${index + 1}'),
                    title: Text(track.name),
                    subtitle: Text(
                      track.artists.isNotEmpty
                          ? track.artists.map((a) => a.name).join(', ')
                          : 'Unknown',
                    ),
                    trailing: Text(
                      '${track.duration.inMinutes}:${(track.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
