import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/track.dart';
import 'track_menu_button.dart';

/// Compact track info bar shown in the player with a menu button.
class PlayerTrackBar extends ConsumerWidget {
  final Track? currentTrack;
  final VoidCallback? onTrackTap;

  const PlayerTrackBar({
    super.key,
    this.currentTrack,
    this.onTrackTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (currentTrack == null) {
      return const SizedBox.shrink();
    }

    final track = currentTrack!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Track artwork
          Container(
            width: 50,
            height: 50,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              image: currentTrack!.image != null
                  ? DecorationImage(
                      image: NetworkImage(currentTrack!.image!),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: currentTrack!.image == null ? Colors.grey[300] : null,
            ),
            child: currentTrack!.image == null
                ? Icon(
                    Icons.music_note,
                    size: 24,
                    color: Colors.grey[600],
                  )
                : null,
          ),
          // Track info
          Expanded(
            child: GestureDetector(
              onTap: onTrackTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentTrack!.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentTrack!.artists.isNotEmpty ? currentTrack!.artists[0].name : 'Unknown Artist',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          // Menu button
          TrackMenuButton(track: track, size: 24),
        ],
      ),
    );
  }
}
