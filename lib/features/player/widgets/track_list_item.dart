import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/track.dart';
import 'track_menu_button.dart';

class TrackListItem extends ConsumerWidget {
  final Track track;
  final int? index;
  final bool isPlaying;
  final bool isLiked;
  final VoidCallback? onTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onShare;
  final VoidCallback? onDownload;
  final VoidCallback? onAddToPlaylist;
  final VoidCallback? onAddToQueue;
  final VoidCallback? onViewDetails;
  final VoidCallback? onReportIssue;

  const TrackListItem({
    Key? key,
    required this.track,
    this.index,
    this.isPlaying = false,
    this.isLiked = false,
    this.onTap,
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
    return Material(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Track number or playing indicator
              if (index != null)
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: isPlaying
                      ? Icon(
                          Icons.music_note,
                          color: Theme.of(context).primaryColor,
                          size: 16,
                        )
                      : Text(
                          '${index! + 1}',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                )
              else
                const SizedBox(width: 8),
              // Track artwork (if available)
              if (track.image != null)
                Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    image: DecorationImage(
                      image: NetworkImage(track.image!),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.grey[300],
                  ),
                  child: Icon(
                    Icons.music_note,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                ),
              // Track info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isPlaying
                                ? Theme.of(context).primaryColor
                                : null,
                            fontWeight: isPlaying
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      track.artists.isNotEmpty ? track.artists[0].name : 'Unknown Artist',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Duration
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  _formatDuration(track.duration.inSeconds),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ),
              // Like button
              IconButton(
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                ),
                onPressed: onLikeTap,
                iconSize: 20,
              ),
              // Menu button
              TrackMenuButton(
                track: track,
                isLiked: isLiked,
                icon: Icons.more_vert,
                size: 20,
                onLikeTap: onLikeTap,
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
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}
