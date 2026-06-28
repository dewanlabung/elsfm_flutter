import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/track.dart';
import '../providers/player_notifier.dart';
import '../providers/track_actions_provider.dart';
import 'track_menu_button.dart';

/// Compact track info bar shown in player with menu
class PlayerTrackBar extends ConsumerWidget {
  final Track? currentTrack;
  final VoidCallback? onTrackTap;

  const PlayerTrackBar({
    Key? key,
    this.currentTrack,
    this.onTrackTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (currentTrack == null) {
      return const SizedBox.shrink();
    }

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
              image: DecorationImage(
                image: NetworkImage(currentTrack!.artwork ?? ''),
                fit: BoxFit.cover,
              ),
            ),
            child: currentTrack!.artwork == null
                ? Container(
                    color: Colors.grey[300],
                    child: Icon(
                      Icons.music_note,
                      size: 24,
                      color: Colors.grey[600],
                    ),
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
                    currentTrack!.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentTrack!.artist?.name ?? 'Unknown Artist',
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
          TrackMenuButton(
            track: currentTrack!,
            icon: Icons.more_vert,
            size: 24,
            onShare: () => _handleShare(context, ref),
            onDownload: () => _handleDownload(context, ref),
            onAddToPlaylist: () => _handleAddToPlaylist(context),
            onAddToQueue: () => _handleAddToQueue(context, ref),
            onViewDetails: () => _handleViewDetails(context),
          ),
        ],
      ),
    );
  }

  Future<void> _handleShare(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(shareTrackProvider(currentTrack!).future);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Share sheet opened')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing: $e')),
      );
    }
  }

  Future<void> _handleDownload(BuildContext context, WidgetRef ref) async {
    try {
      final result = await ref.read(
        downloadTrackProvider(currentTrack!).future,
      );
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download started')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download permission denied')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading: $e')),
      );
    }
  }

  void _handleAddToPlaylist(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add to playlist - coming soon')),
    );
  }

  Future<void> _handleAddToQueue(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(addTrackToQueueProvider(currentTrack!).future);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${currentTrack!.title} added to queue'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding to queue: $e')),
      );
    }
  }

  void _handleViewDetails(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Track details - coming soon')),
    );
  }
}
