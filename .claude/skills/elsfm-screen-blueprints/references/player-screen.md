# Now Playing Screen

Full-featured music player UI.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final playerNotifier = ref.read(playerProvider.notifier);
    final theme = Theme.of(context);

    final currentTrack = playerState.currentTrack;
    if (currentTrack == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Now Playing')),
        body: const Center(child: Text('No track playing')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Artwork (large)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Cover art
                  Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(currentTrack.image ?? ''),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Track title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      currentTrack.name,
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Artist names
                  Text(
                    currentTrack.artists.map((a) => a.name).join(', '),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[400],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          // Progress slider
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: theme.colorScheme.primary,
                    inactiveTrackColor: Colors.grey[800],
                    thumbColor: theme.colorScheme.primary,
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: playerState.duration.inSeconds > 0
                        ? playerState.position.inSeconds /
                            playerState.duration.inSeconds
                        : 0.0,
                    onChanged: (value) {
                      final newPosition = Duration(
                        seconds:
                            (value * playerState.duration.inSeconds).toInt(),
                      );
                      playerNotifier.seek(newPosition);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(playerState.position),
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      _formatDuration(playerState.duration),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Playback controls
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Repeat
                IconButton.filledTonal(
                  onPressed: () => playerNotifier.toggleRepeat(),
                  icon: Icon(
                    switch (playerState.repeatMode) {
                      RepeatMode.none => Icons.repeat,
                      RepeatMode.one => Icons.repeat_one,
                      RepeatMode.all => Icons.repeat,
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Previous
                IconButton(
                  onPressed: playerState.hasPrevious
                      ? () => playerNotifier.previous()
                      : null,
                  icon: const Icon(Icons.skip_previous),
                  iconSize: 36,
                ),
                const SizedBox(width: 8),
                // Play/Pause (Large)
                SizedBox(
                  width: 64,
                  height: 64,
                  child: FilledButton(
                    onPressed: playerState.isLoading
                        ? null
                        : () => playerNotifier.togglePlayPause(),
                    child: Icon(
                      playerState.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Next
                IconButton(
                  onPressed: playerState.hasNext
                      ? () => playerNotifier.next()
                      : null,
                  icon: const Icon(Icons.skip_next),
                  iconSize: 36,
                ),
                const SizedBox(width: 16),
                // Shuffle
                IconButton.filledTonal(
                  onPressed: () => playerNotifier.toggleShuffle(),
                  icon: const Icon(Icons.shuffle),
                ),
              ],
            ),
          ),
          // Queue preview
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Queue',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    itemCount:
                        (playerState.queue.length - playerState.currentIndex)
                            .clamp(0, 3),
                    itemBuilder: (context, index) {
                      final trackIndex =
                          playerState.currentIndex + index + 1;
                      if (trackIndex >= playerState.tracks.length) {
                        return const SizedBox();
                      }
                      final track = playerState.tracks[trackIndex];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
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
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
```

## Usage

```dart
// In AppShell or main app
context.push('/now-playing');

// Or route in GoRouter
GoRoute(
  path: '/now-playing',
  pageBuilder: (context, state) => NoTransitionPage(
    child: NowPlayingScreen(),
  ),
),
```
