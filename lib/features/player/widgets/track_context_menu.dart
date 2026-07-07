import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/track.dart';
import '../providers/player_notifier.dart';
import '../models/track_action.dart';
import '../providers/track_actions_provider.dart';

/// Shows the track context bottom sheet. Call this from any screen.
void showTrackContextSheet(
  BuildContext context,
  Track track, {
  bool isLiked = false,
  VoidCallback? onLikeTap,
  VoidCallback? onDownload,
  VoidCallback? onAddToPlaylist,
  VoidCallback? onShare,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => TrackContextMenu(
      track: track,
      isLiked: isLiked,
      onLikeTap: onLikeTap,
      onDownload: onDownload,
      onAddToPlaylist: onAddToPlaylist,
      onShare: onShare,
    ),
  );
}

class TrackContextMenu extends ConsumerWidget {
  final Track track;
  final VoidCallback? onShare;
  final VoidCallback? onDownload;
  final VoidCallback? onAddToPlaylist;
  final VoidCallback? onViewDetails;
  final VoidCallback? onReportIssue;
  final bool isLiked;
  final VoidCallback? onLikeTap;

  const TrackContextMenu({
    super.key,
    required this.track,
    this.onShare,
    this.onDownload,
    this.onAddToPlaylist,
    this.onViewDetails,
    this.onReportIssue,
    this.isLiked = false,
    this.onLikeTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.watch(availableTrackActionsProvider);
    final artistName = track.artists.isNotEmpty
        ? track.artists.map((a) => a.name).join(', ')
        : 'Unknown Artist';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Track info header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                if (track.image != null && track.image!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      track.image!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _artPlaceholder(),
                    ),
                  )
                else
                  _artPlaceholder(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        artistName,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Play now
          _MenuTile(
            icon: Icons.play_circle_outline,
            label: 'Play now',
            onTap: () {
              Navigator.pop(context);
              ref.read(playerProvider.notifier).playTrack(track);
            },
          ),

          // Add to queue
          _MenuTile(
            icon: Icons.queue_music,
            label: 'Add to queue',
            onTap: () {
              Navigator.pop(context);
              ref.read(playerProvider.notifier).addToQueue(track);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${track.name}" added to queue'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),

          // Like / unlike
          _MenuTile(
            icon: isLiked ? Icons.favorite : Icons.favorite_border,
            label: isLiked ? 'Unlike' : 'Like',
            color: isLiked ? Colors.red : null,
            onTap: () {
              onLikeTap?.call();
              Navigator.pop(context);
            },
          ),

          // Other dynamic actions
          ...actions
              .where((a) =>
                  a != TrackAction.play &&
                  a != TrackAction.addToQueue &&
                  a != TrackAction.like &&
                  a != TrackAction.unlike)
              .map(
                (action) => _MenuTile(
                  icon: _getIcon(action),
                  label: action.label,
                  onTap: () => _handleAction(context, action),
                ),
              ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _artPlaceholder() => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.music_note, color: Colors.grey),
      );

  void _handleAction(BuildContext context, TrackAction action) {
    Navigator.pop(context);
    switch (action) {
      case TrackAction.share:
        onShare?.call();
      case TrackAction.download:
        onDownload?.call();
      case TrackAction.addToPlaylist:
        onAddToPlaylist?.call();
      case TrackAction.viewDetails:
        onViewDetails?.call();
      case TrackAction.reportIssue:
        onReportIssue?.call();
      default:
        break;
    }
  }

  IconData _getIcon(TrackAction action) {
    return switch (action) {
      TrackAction.play          => Icons.play_arrow,
      TrackAction.addToPlaylist => Icons.playlist_add,
      TrackAction.share         => Icons.share,
      TrackAction.download      => Icons.download,
      TrackAction.like          => Icons.favorite,
      TrackAction.unlike        => Icons.favorite_border,
      TrackAction.addToQueue    => Icons.queue_music,
      TrackAction.viewDetails   => Icons.info_outline,
      TrackAction.reportIssue   => Icons.flag_outlined,
    };
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 22, color: color),
      title: Text(label, style: TextStyle(color: color)),
      onTap: onTap,
      dense: true,
    );
  }
}
