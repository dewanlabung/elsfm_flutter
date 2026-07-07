import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/app_config.dart';
import '../providers/player_notifier.dart';
import '../providers/player_overlay_notifier.dart';
import '../widgets/playback_controls.dart';
import '../widgets/playback_progress.dart';
import '../widgets/queue_view.dart';

/// Fullscreen player screen shown when player is maximized.
/// Inspired by web's player-overlay.tsx fullscreen implementation.
class FullscreenPlayerScreen extends ConsumerWidget {
  const FullscreenPlayerScreen({super.key});

  String? _resolveImage(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    return '${AppConfig.webBaseUrl}/$raw';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final overlayState = ref.watch(playerOverlayStateProvider);
    final currentTrack = playerState.currentTrack;
    final colorScheme = Theme.of(context).colorScheme;

    if (currentTrack == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Player'),
          leading: IconButton(
            icon: const Icon(Icons.expand_more),
            onPressed: () =>
                ref.read(playerOverlayStateProvider.notifier).close(),
          ),
        ),
        body: const Center(
          child: Text('No track playing'),
        ),
      );
    }

    final imageUrl = _resolveImage(currentTrack.image);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Android back button closes fullscreen
        if (didPop) {
          ref.read(playerOverlayStateProvider.notifier).close();
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header with close button ────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.expand_more),
                      onPressed: () =>
                          ref.read(playerOverlayStateProvider.notifier).close(),
                      tooltip: 'Collapse to mini-player',
                    ),
                    Text(
                      'Now Playing',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      icon: Icon(overlayState.isQueueOpen
                          ? Icons.queue_music
                          : Icons.queue_music_outlined),
                      onPressed: () =>
                          ref.read(playerOverlayStateProvider.notifier).toggleQueue(),
                      tooltip: 'Toggle queue',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Main content (album art or queue) ─────────────────────────
              if (!overlayState.isQueueOpen)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Album artwork
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: imageUrl != null
                                ? Image.network(
                                    imageUrl,
                                    width: 280,
                                    height: 280,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _albumArtPlaceholder(280),
                                  )
                                : _albumArtPlaceholder(280),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Track info
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              Text(
                                currentTrack.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                currentTrack.artists
                                    .map((a) => a.name)
                                    .join(', '),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                )
              else
                // Queue view
                const Expanded(
                  child: QueueView(),
                ),

              const SizedBox(height: 16),

              // ── Playback progress ────────────────────────────────────────
              PlaybackProgress(
                onSeek: () {
                  // Progress slider updates player via its own logic
                },
              ),
              const SizedBox(height: 16),

              // ── Playback controls ────────────────────────────────────────
              const PlaybackControls(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _albumArtPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.music_note,
        size: size * 0.3,
        color: Colors.grey[600],
      ),
    );
  }
}
