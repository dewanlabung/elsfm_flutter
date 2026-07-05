import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_config.dart';
import '../../../data/models/track.dart';
import '../providers/playlist_provider.dart';
import '../../player/providers/player_notifier.dart';

class PlaylistScreen extends ConsumerStatefulWidget {
  final int playlistId;

  const PlaylistScreen({super.key, required this.playlistId});

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

  String? _resolveImage(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    return '${AppConfig.webBaseUrl}/$raw';
  }

  String _fmt(Duration d) {
    final m = d.inSeconds ~/ 60;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final playlistAsync = ref.watch(playlistProvider);
    final tracksAsync = ref.watch(playlistTracksProvider);

    return Scaffold(
      body: playlistAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (playlist) {
          final imageUrl = _resolveImage(playlist['image'] as String?);
          final name = (playlist['name'] as String?) ?? 'Playlist';
          final description = (playlist['description'] as String?) ?? '';
          final ownerName =
              (playlist['owner'] as Map?)?['name'] as String? ?? '';

          return CustomScrollView(
            slivers: [
              // ── Hero header ──────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    name,
                    style: const TextStyle(
                      shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                    ),
                  ),
                  background: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _PlaylistPlaceholder(name: name),
                        )
                      : _PlaylistPlaceholder(name: name),
                ),
              ),

              // ── Meta info ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (description.isNotEmpty)
                        Text(description,
                            style: Theme.of(context).textTheme.bodyMedium),
                      if (ownerName.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'by $ownerName',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Action buttons ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: tracksAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (tracks) => Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Play All'),
                            onPressed: tracks.isEmpty
                                ? null
                                : () {
                                    ref
                                        .read(playerProvider.notifier)
                                        .setQueue(tracks, startIndex: 0);
                                    context.push('/now-playing');
                                  },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.outlined(
                          icon: const Icon(Icons.shuffle),
                          tooltip: 'Shuffle',
                          onPressed: tracks.isEmpty
                              ? null
                              : () {
                                  final shuffled = List<Track>.from(tracks)
                                    ..shuffle();
                                  ref
                                      .read(playerProvider.notifier)
                                      .setQueue(shuffled, startIndex: 0);
                                  context.push('/now-playing');
                                },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Track list ────────────────────────────────────────────────
              tracksAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (err, _) => SliverToBoxAdapter(
                  child: Center(child: Text('Error: $err')),
                ),
                data: (tracks) => SliverList.builder(
                  itemCount: tracks.length + 1,
                  itemBuilder: (context, index) {
                    if (index == tracks.length) {
                      return const SizedBox(height: 100);
                    }
                    final track = tracks[index];
                    final trackImgUrl = _resolveImage(track.image);
                    return ListTile(
                      leading: trackImgUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                trackImgUrl,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _TrackNumBox(num: index + 1),
                              ),
                            )
                          : _TrackNumBox(num: index + 1),
                      title: Text(
                        track.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        track.artists.map((a) => a.name).join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        _fmt(track.duration),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      onTap: () {
                        ref
                            .read(playerProvider.notifier)
                            .setQueue(tracks, startIndex: index);
                        context.push('/now-playing');
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlaylistPlaceholder extends StatelessWidget {
  final String name;
  const _PlaylistPlaceholder({required this.name});

  Color get _color {
    final hue = (name.codeUnits.fold(0, (a, b) => a + b) % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.4, 0.3).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _color,
      child: const Center(
        child: Icon(Icons.playlist_play, size: 80, color: Colors.white54),
      ),
    );
  }
}

class _TrackNumBox extends StatelessWidget {
  final int num;
  const _TrackNumBox({required this.num});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Center(
        child: Text('$num', style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}
