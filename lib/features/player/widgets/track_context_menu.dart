import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/track.dart';
import '../models/track_action.dart';
import '../providers/track_actions_provider.dart';

typedef TrackActionCallback = Future<void> Function(TrackAction action, Track track);

class TrackContextMenu extends ConsumerWidget {
  final Track track;
  final VoidCallback? onShare;
  final VoidCallback? onDownload;
  final VoidCallback? onAddToPlaylist;
  final VoidCallback? onAddToQueue;
  final VoidCallback? onViewDetails;
  final VoidCallback? onReportIssue;
  final Offset? position;
  final bool isLiked;
  final VoidCallback? onLikeTap;

  const TrackContextMenu({
    Key? key,
    required this.track,
    this.onShare,
    this.onDownload,
    this.onAddToPlaylist,
    this.onAddToQueue,
    this.onViewDetails,
    this.onReportIssue,
    this.position,
    this.isLiked = false,
    this.onLikeTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.watch(availableTrackActionsProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Track info header
            Padding(
              padding: const EdgeInsets.all(12),
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
            const Divider(height: 1, indent: 0, endIndent: 0),
            // Action items
            ...actions.map(
              (action) => _TrackMenuItemTile(
                action: action,
                onTap: () => _handleAction(context, action),
              ),
            ),
            // Like action
            _TrackMenuItemTile(
              action: isLiked ? TrackAction.unlike : TrackAction.like,
              onTap: () {
                onLikeTap?.call();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, TrackAction action) async {
    Navigator.pop(context);

    switch (action) {
      case TrackAction.share:
        await onShare?.call();
      case TrackAction.download:
        await onDownload?.call();
      case TrackAction.addToPlaylist:
        await onAddToPlaylist?.call();
      case TrackAction.addToQueue:
        await onAddToQueue?.call();
      case TrackAction.viewDetails:
        await onViewDetails?.call();
      case TrackAction.reportIssue:
        await onReportIssue?.call();
      default:
        break;
    }
  }
}

class _TrackMenuItemTile extends StatelessWidget {
  final TrackAction action;
  final VoidCallback onTap;

  const _TrackMenuItemTile({
    Key? key,
    required this.action,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                _getIcon(action),
                size: 20,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              const SizedBox(width: 16),
              Text(
                action.label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(TrackAction action) {
    return switch (action) {
      TrackAction.play => Icons.play_arrow,
      TrackAction.addToPlaylist => Icons.playlist_add,
      TrackAction.share => Icons.share,
      TrackAction.download => Icons.download,
      TrackAction.like => Icons.favorite,
      TrackAction.unlike => Icons.favorite_border,
      TrackAction.addToQueue => Icons.queue_music,
      TrackAction.viewDetails => Icons.info_outline,
      TrackAction.reportIssue => Icons.flag_outlined,
    };
  }
}
