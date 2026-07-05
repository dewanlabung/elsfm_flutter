import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_config.dart';
import '../../../data/models/track.dart';
import '../providers/player_notifier.dart';
import '../providers/like_notifier.dart';
import '../widgets/playback_progress.dart';
import '../widgets/playback_controls.dart';
import '../widgets/track_context_menu.dart';
import '../widgets/queue_bottom_sheet.dart';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  String? _resolveImage(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    return '${AppConfig.webBaseUrl}/$raw';
  }

  void _showOptions(BuildContext context, WidgetRef ref, Track track) {
    final isLiked = ref.read(likeNotifierProvider).contains(track.id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TrackContextMenu(
        track: track,
        isLiked: isLiked,
        onLikeTap: () =>
            ref.read(likeNotifierProvider.notifier).toggle(track.id),
        onAddToQueue: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to queue')),
        ),
        onShare: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Share coming soon')),
        ),
        onDownload: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download coming soon')),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final currentTrack = playerState.currentTrack;
    final likedIds = ref.watch(likeNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.expand_more),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Text('Now Playing',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(letterSpacing: 1.5)),
            if (currentTrack != null)
              Text(
                currentTrack.album?.name ?? '',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.queue_music),
            tooltip: 'Queue',
            onPressed: () => showQueueBottomSheet(context),
          ),
          if (currentTrack != null)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showOptions(context, ref, currentTrack),
            ),
        ],
      ),
      body: currentTrack == null
          ? const Center(child: Text('No track loaded'))
          : GestureDetector(
              onHorizontalDragEnd: (details) {
                final v = details.primaryVelocity ?? 0;
                if (v < -300) ref.read(playerProvider.notifier).next();
                if (v > 300) ref.read(playerProvider.notifier).previous();
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.primaryContainer.withOpacity(0.7),
                      colorScheme.surface,
                    ],
                    stops: const [0.0, 0.6],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // ── Album art ─────────────────────────────────────────
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(40, 16, 40, 16),
                          child: _AlbumArt(
                            imageUrl: _resolveImage(currentTrack.image),
                            trackName: currentTrack.name,
                            isPlaying: playerState.isPlaying,
                          ),
                        ),
                      ),

                      // ── Track info + like ─────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentTrack.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currentTrack.artists
                                        .map((a) => a.name)
                                        .join(', '),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                            color: colorScheme.onSurface
                                                .withOpacity(0.65)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                likedIds.contains(currentTrack.id)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: likedIds.contains(currentTrack.id)
                                    ? Colors.red
                                    : null,
                              ),
                              onPressed: () => ref
                                  .read(likeNotifierProvider.notifier)
                                  .toggle(currentTrack.id),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ── Playback error (e.g. stream failed) ───────────────
                      if (playerState.error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    playerState.error!,
                                    style: const TextStyle(color: Colors.red, fontSize: 12),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // ── Progress ──────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: PlaybackProgress(),
                      ),

                      // ── Controls ──────────────────────────────────────────
                      const PlaybackControls(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _AlbumArt extends StatelessWidget {
  final String? imageUrl;
  final String trackName;
  final bool isPlaying;

  const _AlbumArt({
    this.imageUrl,
    required this.trackName,
    required this.isPlaying,
  });

  Color get _color {
    final hue =
        (trackName.codeUnits.fold(0, (a, b) => a + b) % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.4, 0.35).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isPlaying ? 1.0 : 0.88,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: imageUrl != null
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder,
                )
              : _placeholder,
        ),
      ),
    );
  }

  Widget get _placeholder => Container(
        color: _color,
        child: const Center(
          child: Icon(Icons.music_note, size: 80, color: Colors.white54),
        ),
      );
}
