import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/player_notifier.dart';

class PlaybackProgress extends ConsumerStatefulWidget {
  final VoidCallback? onSeek;
  const PlaybackProgress({super.key, this.onSeek});

  @override
  ConsumerState<PlaybackProgress> createState() => _PlaybackProgressState();
}

class _PlaybackProgressState extends ConsumerState<PlaybackProgress> {
  double? _dragging;

  String _fmt(Duration d) {
    final m = d.inSeconds ~/ 60;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final total = playerState.duration.inSeconds.toDouble();
    final current = total > 0
        ? playerState.position.inSeconds.toDouble().clamp(0.0, total)
        : 0.0;

    final displayValue = _dragging ?? current;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: total > 0 ? displayValue.clamp(0.0, total) : 0.0,
            max: total > 0 ? total : 1.0,
            onChanged: total > 0
                ? (v) => setState(() => _dragging = v)
                : null,
            onChangeEnd: total > 0
                ? (v) {
                    setState(() => _dragging = null);
                    ref
                        .read(playerProvider.notifier)
                        .seek(Duration(seconds: v.toInt()));
                    widget.onSeek?.call();
                  }
                : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_fmt(Duration(seconds: displayValue.toInt())),
                  style: Theme.of(context).textTheme.bodySmall),
              Text(_fmt(playerState.duration),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
