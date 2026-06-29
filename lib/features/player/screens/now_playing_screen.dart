import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/player_notifier.dart';
import 'package:elsfm/data/models/player_state.dart' as player_state_model;
import '../../lyrics/screens/lyrics_screen.dart';

/// Now Playing screen — full-screen dark player matching elsfm.com mobile style
class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  String _resolveImageUrl(String? image) {
    if (image == null || image.isEmpty) return '';
    if (image.startsWith('http')) return image;
    return 'https://www.elsfm.com/$image';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final currentTrack = playerState.currentTrack;
    final playerReady = ref.watch(playerServiceProvider).hasValue;

    ref.listen<player_state_model.PlayerState>(playerProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${next.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    final imageUrl = _resolveImageUrl(currentTrack?.image);
    final screenWidth = MediaQuery.of(context).size.width;
    final artSize = screenWidth * 0.8;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background: blurred album art
          if (imageUrl.isNotEmpty)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.black),
                ),
              ),
            ),
          // Dark overlay
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
          // Content
          SafeArea(
            child: currentTrack == null
                ? const Center(
                    child: Text(
                      'No track loaded',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : Column(
                    children: [
                      // Top bar
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.expand_more,
                                  color: Colors.white),
                              onPressed: () => context.pop(),
                            ),
                            const Spacer(),
                            const Text(
                              'NOW PLAYING',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.more_vert,
                                  color: Colors.white),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                      // Album art
                      Expanded(
                        child: Center(
                          child: Container(
                            width: artSize,
                            height: artSize,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.grey[900],
                                        child: const Icon(Icons.music_note,
                                            size: 80, color: Colors.white54),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.grey[900],
                                      child: const Icon(Icons.music_note,
                                          size: 80, color: Colors.white54),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Track name
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          currentTrack.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Artist name
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          currentTrack.artists.map((a) => a.name).join(', '),
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Heart / lyrics / share row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.favorite_border,
                                  color: Colors.white70),
                              onPressed: () {},
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.lyrics_outlined,
                                  color: Colors.white70),
                              tooltip: 'Lyrics',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        LyricsScreen(track: currentTrack),
                                  ),
                                );
                              },
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.share,
                                  color: Colors.white70),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                      // Seek bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: Colors.white,
                                inactiveTrackColor:
                                    Colors.white.withOpacity(0.3),
                                thumbColor: Colors.white,
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6),
                                trackHeight: 3,
                                overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 14),
                              ),
                              child: Slider(
                                value: playerState.duration.inSeconds > 0
                                    ? playerState.position.inSeconds
                                        .toDouble()
                                        .clamp(
                                            0,
                                            playerState.duration.inSeconds
                                                .toDouble())
                                    : 0,
                                max: playerState.duration.inSeconds > 0
                                    ? playerState.duration.inSeconds.toDouble()
                                    : 1,
                                onChanged: playerReady
                                    ? (value) {
                                        ref
                                            .read(playerProvider.notifier)
                                            .seek(Duration(
                                                seconds: value.toInt()));
                                      }
                                    : null,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(playerState.position),
                                  style: const TextStyle(
                                      color: Colors.white60, fontSize: 11),
                                ),
                                Text(
                                  _formatDuration(playerState.duration),
                                  style: const TextStyle(
                                      color: Colors.white60, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Playback controls
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Shuffle
                            IconButton(
                              icon: Icon(
                                playerState.isShuffled
                                    ? Icons.shuffle_on
                                    : Icons.shuffle,
                                color: playerState.isShuffled
                                    ? Colors.white
                                    : Colors.white54,
                              ),
                              onPressed: playerReady
                                  ? () => ref
                                      .read(playerProvider.notifier)
                                      .toggleShuffle()
                                  : null,
                            ),
                            // Previous
                            IconButton(
                              icon: const Icon(Icons.skip_previous,
                                  color: Colors.white),
                              iconSize: 36,
                              onPressed: playerReady
                                  ? () => ref
                                      .read(playerProvider.notifier)
                                      .previous()
                                  : null,
                            ),
                            // Play / Pause
                            IconButton(
                              icon: Icon(
                                playerState.isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                color: Colors.white,
                              ),
                              iconSize: 64,
                              onPressed: playerReady
                                  ? () => ref
                                      .read(playerProvider.notifier)
                                      .togglePlayPause()
                                  : null,
                            ),
                            // Next
                            IconButton(
                              icon: const Icon(Icons.skip_next,
                                  color: Colors.white),
                              iconSize: 36,
                              onPressed: playerReady
                                  ? () =>
                                      ref.read(playerProvider.notifier).next()
                                  : null,
                            ),
                            // Repeat
                            IconButton(
                              icon: Icon(
                                _getRepeatIcon(playerState.repeatMode),
                                color: playerState.repeatMode != player_state_model.RepeatMode.none
                                    ? Colors.white
                                    : Colors.white54,
                              ),
                              onPressed: playerReady
                                  ? () => ref
                                      .read(playerProvider.notifier)
                                      .toggleRepeat()
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  IconData _getRepeatIcon(player_state_model.RepeatMode mode) {
    switch (mode) {
      case player_state_model.RepeatMode.none:
        return Icons.repeat;
      case player_state_model.RepeatMode.one:
        return Icons.repeat_one;
      case player_state_model.RepeatMode.all:
        return Icons.repeat_on;
    }
  }
}
