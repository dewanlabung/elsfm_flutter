import 'package:flutter/material.dart';
import '../../../data/models/track.dart';
import 'track_context_menu.dart';

/// Simple ... icon button that opens the track context bottom sheet.
class TrackMenuButton extends StatelessWidget {
  final Track track;
  final double? size;
  const TrackMenuButton({super.key, required this.track, this.size});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.more_vert, size: size),
      onPressed: () => showTrackContextSheet(context, track),
      tooltip: 'More options',
    );
  }
}
