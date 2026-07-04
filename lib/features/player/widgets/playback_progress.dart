import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/player_notifier.dart';

/// Playback progress widget showing current position and total duration
class PlaybackProgress extends ConsumerWidget {
  final VoidCallback? onSeek;

  const PlaybackProgress({super.key, this.onSeek});

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);

    return Column(
      children: [
        // Progress slider
        Slider(
          value: playerState.duration.inSeconds > 0
              ? playerState.position.inSeconds
                  .toDouble()
                  .clamp(0, playerState.duration.inSeconds.toDouble())
              : 0,
          max: playerState.duration.inSeconds > 0
              ? playerState.duration.inSeconds.toDouble()
              : 1.0,
          onChanged: playerState.duration.inSeconds > 0
              ? (value) {} // enables interaction; seek committed in onChangeEnd
              : null,
          onChangeEnd: (value) {
            ref.read(playerProvider.notifier).seek(
                  Duration(seconds: value.toInt()),
                );
            onSeek?.call();
          },
          activeColor: Theme.of(context).colorScheme.primary,
          inactiveColor: Colors.grey[300],
        ),
        // Time display
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(playerState.position),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                _formatDuration(playerState.duration),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
