import 'package:flutter/material.dart';

/// Track information
class TrackInfo {
  final String title;
  final String artist;
  final String? artworkUrl;
  final Duration duration;
  final Duration position;
  final bool isPlaying;

  TrackInfo({
    required this.title,
    required this.artist,
    this.artworkUrl,
    required this.duration,
    required this.position,
    required this.isPlaying,
  });

  double get progress =>
      duration.inSeconds > 0 ? position.inSeconds / duration.inSeconds : 0.0;
}

/// Compact playback control bar for bottom of screen
class PlaybackControlBar extends StatelessWidget {
  final TrackInfo track;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onTap;

  const PlaybackControlBar({
    required this.track,
    required this.onPlayPause,
    required this.onNext,
    required this.onTap,
    super.key,
  });

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.grey[900],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: track.progress,
              minHeight: 2,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.green[400]!,
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Artwork
                  if (track.artworkUrl != null)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        image: DecorationImage(
                          image: NetworkImage(track.artworkUrl!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.grey[800],
                      ),
                      child: const Icon(Icons.music_note, color: Colors.white54),
                    ),
                  const SizedBox(width: 12),
                  // Track info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          track.title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          track.artist,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Time display
                  Text(
                    _formatDuration(track.position),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Play/Pause button
                  IconButton(
                    icon: Icon(
                      track.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.green[400],
                    ),
                    onPressed: onPlayPause,
                    iconSize: 24,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                  // Next button
                  IconButton(
                    icon: Icon(
                      Icons.skip_next,
                      color: Colors.white70,
                    ),
                    onPressed: onNext,
                    iconSize: 24,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Expanded full-screen player view
class FullScreenPlayer extends StatelessWidget {
  final TrackInfo track;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onClose;

  const FullScreenPlayer({
    required this.track,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    required this.onClose,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.expand_more),
                  onPressed: onClose,
                  color: Colors.white,
                ),
                const Text('Now Playing', style: TextStyle(color: Colors.white)),
                const SizedBox(width: 48),
              ],
            ),
          ),
          // Artwork
          Expanded(
            child: Center(
              child: track.artworkUrl != null
                  ? Image.network(
                      track.artworkUrl!,
                      fit: BoxFit.cover,
                      width: 250,
                      height: 250,
                    )
                  : Container(
                      width: 250,
                      height: 250,
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.music_note,
                        size: 100,
                        color: Colors.white54,
                      ),
                    ),
            ),
          ),
          // Track info
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  track.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  track.artist,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: track.progress,
                  minHeight: 3,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.green[400]!,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${track.position.inMinutes}:${(track.position.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '${track.duration.inMinutes}:${(track.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  onPressed: onPrevious,
                  color: Colors.white,
                  iconSize: 32,
                ),
                FloatingActionButton(
                  onPressed: onPlayPause,
                  backgroundColor: Colors.green[400],
                  child: Icon(
                    track.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.black,
                    size: 32,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: onNext,
                  color: Colors.white,
                  iconSize: 32,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
