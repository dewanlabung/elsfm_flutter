# Player Components

Music playback UI components from the ELSFM player.

## PlaybackControlBar

Compact player bar shown at bottom of main screens. Displays current track, play/pause, progress, and expands to full player.

```dart
class TrackInfo {
  final String title;
  final String artist;
  final String? artworkUrl;
  final Duration duration;
  final Duration position;
  final bool isPlaying;

  double get progress => duration.inSeconds > 0 
      ? position.inSeconds / duration.inSeconds 
      : 0.0;
}

PlaybackControlBar(
  track: TrackInfo(
    title: 'Track Name',
    artist: 'Artist Name',
    artworkUrl: imageUrl,
    duration: const Duration(minutes: 3, seconds: 45),
    position: const Duration(minutes: 1, seconds: 30),
    isPlaying: true,
  ),
  onPlayPause: () => playerNotifier.togglePlayPause(),
  onNext: () => playerNotifier.next(),
  onTap: () => context.push('/now-playing'),
)
```

### Structure
```
┌─────────────────────────────┐
│ ▓▓▓░░░░░░░░░░░░░░░░░░░░░░░ │ Progress bar (2px)
├─────────────────────────────┤
│ [Image] Title               │
│         Artist              │
│         [▶ ⏭] Next         │
└─────────────────────────────┘
```

### Implementation Details

- **Progress Bar:** Green (#1DB954) to indicate playback position
- **Artwork:** 48x48 dp with 4px border radius
- **Spacing:** 16px horizontal, 8px vertical padding
- **Tap Target:** Entire bar is tappable (minimum 48dp height)
- **Colors:** Dark grey background (Colors.grey[900])
- **Icons:** Material Icons (play_arrow, pause, skip_next)

## ProgressSlider

Full-width seekable progress bar in Now Playing screen.

```dart
ProgressSlider(
  duration: playerState.duration,
  position: playerState.position,
  onSeek: (duration) => playerNotifier.seek(duration),
)
```

### Features
- Smooth thumb dragging
- Visual feedback during drag
- Time display (current / total)
- Non-blocking layout (doesn't prevent other interactions)

```dart
class ProgressSlider extends StatefulWidget {
  final Duration duration;
  final Duration position;
  final Function(Duration) onSeek;

  @override
  State<ProgressSlider> createState() => _ProgressSliderState();
}

class _ProgressSliderState extends State<ProgressSlider> {
  late Duration _dragPosition;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentPosition = _isDragging ? _dragPosition : widget.position;
    final progress = widget.duration.inSeconds > 0
        ? currentPosition.inSeconds / widget.duration.inSeconds
        : 0.0;

    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: Colors.grey[800],
            thumbColor: theme.colorScheme.primary,
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            onChangeStart: (_) => setState(() => _isDragging = true),
            onChanged: (val) {
              final newPosition = Duration(
                seconds: (val * widget.duration.inSeconds).toInt(),
              );
              setState(() => _dragPosition = newPosition);
            },
            onChangeEnd: (val) {
              final newPosition = Duration(
                seconds: (val * widget.duration.inSeconds).toInt(),
              );
              widget.onSeek(newPosition);
              setState(() => _isDragging = false);
            },
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(currentPosition),
                style: theme.textTheme.bodySmall,
              ),
              Text(
                _formatDuration(widget.duration),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
```

## PlaybackControls

Full-featured playback button row with repeat and shuffle.

```dart
class PlaybackControls extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerNotifierProvider);
    final playerNotifier = ref.read(playerNotifierProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Repeat button
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
        ),
        const SizedBox(width: 8),
        // Play/Pause (Large)
        SizedBox(
          width: 56,
          height: 56,
          child: FilledButton(
            onPressed: playerState.isLoading
                ? null
                : () => playerNotifier.togglePlayPause(),
            child: Icon(
              playerState.isPlaying ? Icons.pause : Icons.play_arrow,
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
        ),
        const SizedBox(width: 16),
        // Shuffle button
        IconButton.filledTonal(
          onPressed: () => playerNotifier.toggleShuffle(),
          icon: const Icon(Icons.shuffle),
        ),
      ],
    );
  }
}
```

## VolumeControl

Volume slider for playback volume (separate from system volume).

```dart
VolumeControl(
  volume: playerState.volume,
  onVolumeChange: (newVolume) => playerNotifier.setVolume(newVolume),
)
```

```dart
class VolumeControl extends StatelessWidget {
  final double volume; // 0.0 to 1.0
  final Function(double) onVolumeChange;

  const VolumeControl({
    required this.volume,
    required this.onVolumeChange,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.volume_down,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Slider(
            value: volume,
            min: 0.0,
            max: 1.0,
            onChanged: onVolumeChange,
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.volume_up,
          color: Colors.grey[600],
        ),
      ],
    );
  }
}
```

## NowPlayingScreen

Complete player screen with artwork, track info, controls, and queue.

```dart
class NowPlayingScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerNotifierProvider);
    final currentTrack = playerState.currentTrack;

    if (currentTrack == null) {
      return const Scaffold(
        body: Center(child: Text('No track playing')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Large artwork
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
                  Text(
                    currentTrack.name,
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Artist name
                  Text(
                    currentTrack.artists.map((a) => a.name).join(', '),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          // Progress slider
          Padding(
            padding: const EdgeInsets.all(16),
            child: ProgressSlider(
              duration: playerState.duration,
              position: playerState.position,
              onSeek: (d) => ref.read(playerNotifierProvider.notifier).seek(d),
            ),
          ),
          // Playback controls
          const Padding(
            padding: EdgeInsets.all(24),
            child: PlaybackControls(),
          ),
        ],
      ),
    );
  }
}
```

## MiniPlayer

Collapsed version shown above BottomNavigationBar in main screens.

```dart
MiniPlayer(
  onExpanded: () => context.push('/now-playing'),
)
```

Shows:
- Track artwork (small)
- Track title + artist
- Play/pause button
- Next button
- Tap to expand

Automatic height adjustment based on presence of active playback.
