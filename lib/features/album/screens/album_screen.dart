import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/album_provider.dart';

class AlbumScreen extends ConsumerStatefulWidget {
  final int albumId;

  const AlbumScreen({
    super.key,
    required this.albumId,
  });

  @override
  ConsumerState<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends ConsumerState<AlbumScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(selectedAlbumIdProvider.notifier).state = widget.albumId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final albumAsync = ref.watch(albumProvider);
    final tracksAsync = ref.watch(albumTracksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Album')),
      body: albumAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
        data: (album) => CustomScrollView(
          slivers: [
            // Album header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.album, size: 100, color: Color(0xFF1DB954)),
                    const SizedBox(height: 16),
                    Text(
                      album['name'] ?? 'Unknown',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      album['artists']?[0]?['name'] ?? 'Unknown artist',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (album['release_year'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${album['release_year']}',
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
