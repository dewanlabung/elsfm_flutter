import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/track.dart';
import '../providers/track_actions_provider.dart';
import 'track_context_menu.dart';

class TrackMenuButton extends ConsumerWidget {
  final Track track;
  final bool isLiked;
  final VoidCallback? onLikeTap;
  final VoidCallback? onShare;
  final VoidCallback? onDownload;
  final VoidCallback? onAddToPlaylist;
  final VoidCallback? onAddToQueue;
  final VoidCallback? onViewDetails;
  final VoidCallback? onReportIssue;
  final IconData icon;
  final double? size;

  const TrackMenuButton({
    Key? key,
    required this.track,
    this.isLiked = false,
    this.onLikeTap,
    this.onShare,
    this.onDownload,
    this.onAddToPlaylist,
    this.onAddToQueue,
    this.onViewDetails,
    this.onReportIssue,
    this.icon = Icons.more_vert,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: Icon(icon),
      iconSize: size,
      onPressed: () => _showTrackMenu(context),
    );
  }

  void _showTrackMenu(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: TrackContextMenu(
          track: track,
          isLiked: isLiked,
          onLikeTap: onLikeTap,
          onShare: onShare,
          onDownload: onDownload,
          onAddToPlaylist: onAddToPlaylist,
          onAddToQueue: onAddToQueue,
          onViewDetails: onViewDetails,
          onReportIssue: onReportIssue,
        ),
      ),
    );
  }
}

/// Alternative: Show menu as bottom sheet (mobile-optimized)
class TrackMenuBottomSheet extends ConsumerWidget {
  final Track track;
  final bool isLiked;
  final VoidCallback? onLikeTap;
  final VoidCallback? onShare;
  final VoidCallback? onDownload;
  final VoidCallback? onAddToPlaylist;
  final VoidCallback? onAddToQueue;
  final VoidCallback? onViewDetails;
  final VoidCallback? onReportIssue;

  const TrackMenuBottomSheet({
    Key? key,
    required this.track,
    this.isLiked = false,
    this.onLikeTap,
    this.onShare,
    this.onDownload,
    this.onAddToPlaylist,
    this.onAddToQueue,
    this.onViewDetails,
    this.onReportIssue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Track info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    track.artist?.name ?? 'Unknown Artist',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Menu items
            TrackContextMenu(
              track: track,
              isLiked: isLiked,
              onLikeTap: () {
                onLikeTap?.call();
                Navigator.pop(context);
              },
              onShare: onShare,
              onDownload: onDownload,
              onAddToPlaylist: onAddToPlaylist,
              onAddToQueue: onAddToQueue,
              onViewDetails: onViewDetails,
              onReportIssue: onReportIssue,
            ),
          ],
        ),
      ),
    );
  }
}

/// Show track menu as bottom sheet
void showTrackMenuBottomSheet(
  BuildContext context,
  Track track, {
  bool isLiked = false,
  VoidCallback? onLikeTap,
  VoidCallback? onShare,
  VoidCallback? onDownload,
  VoidCallback? onAddToPlaylist,
  VoidCallback? onAddToQueue,
  VoidCallback? onViewDetails,
  VoidCallback? onReportIssue,
}) {
  showModalBottomSheet(
    context: context,
    builder: (context) => TrackMenuBottomSheet(
      track: track,
      isLiked: isLiked,
      onLikeTap: onLikeTap,
      onShare: onShare,
      onDownload: onDownload,
      onAddToPlaylist: onAddToPlaylist,
      onAddToQueue: onAddToQueue,
      onViewDetails: onViewDetails,
      onReportIssue: onReportIssue,
    ),
  );
}
