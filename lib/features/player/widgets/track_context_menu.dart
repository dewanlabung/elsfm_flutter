import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/models/track.dart';
import '../../../data/providers/api_client_provider.dart';
import '../../player/providers/player_notifier.dart';

String _resolveImg(String? img) {
  if (img == null || img.isEmpty) return '';
  if (img.startsWith('http')) return img;
  return 'https://www.elsfm.com/$img';
}

/// Shows the track context bottom sheet. Call this from any screen.
void showTrackContextSheet(BuildContext context, Track track) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => TrackContextSheet(track: track),
  );
}

class TrackContextSheet extends ConsumerStatefulWidget {
  final Track track;
  const TrackContextSheet({super.key, required this.track});

  @override
  ConsumerState<TrackContextSheet> createState() => _TrackContextSheetState();
}

class _TrackContextSheetState extends ConsumerState<TrackContextSheet> {
  bool _isLiked = false;
  bool _likeLoading = false;

  @override
  Widget build(BuildContext context) {
    final track = widget.track;
    final imageUrl = _resolveImg(track.image);
    final artistNames = track.artists.map((a) => a.name).join(', ');

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imgFallback(),
                        )
                      : _imgFallback(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      if (artistNames.isNotEmpty)
                        Text(
                          artistNames,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // actions
          _item(Icons.queue_music, 'Add to queue', () {
            final notifier = ref.read(playerProvider.notifier);
            notifier.playTrack(track);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Added to queue')),
            );
          }),
          _item(Icons.playlist_add, 'Add to playlist', () {
            Navigator.pop(context);
            _showAddToPlaylistSheet(context, ref, track);
          }),
          _item(
            _isLiked ? Icons.favorite : Icons.favorite_border,
            _isLiked ? 'Remove from library' : 'Like',
            _likeLoading ? null : () => _toggleLike(context),
          ),
          _item(Icons.share, 'Share', () {
            Navigator.pop(context);
            Share.share(
              'https://www.elsfm.com/track/${track.id}',
              subject: track.name,
            );
          }),
          _item(Icons.link, 'Copy link', () {
            Clipboard.setData(ClipboardData(
                text: 'https://www.elsfm.com/track/${track.id}'));
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Link copied to clipboard')),
            );
          }),
          if (track.artists.isNotEmpty)
            _item(Icons.person, 'Go to artist', () {
              Navigator.pop(context);
              context.push('/artist/${track.artists.first.id}');
            }),
          if (track.album != null)
            _item(Icons.album, 'Go to album', () {
              Navigator.pop(context);
              context.push('/album/${track.album!.id}');
            }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _imgFallback() => Container(
        width: 48,
        height: 48,
        color: Colors.grey.withOpacity(0.2),
        child: const Icon(Icons.music_note, color: Colors.grey),
      );

  Widget _item(IconData icon, String label, VoidCallback? onTap) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(label),
      onTap: onTap,
      enabled: onTap != null,
    );
  }

  Future<void> _toggleLike(BuildContext ctx) async {
    setState(() => _likeLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final endpoint = _isLiked
          ? '/users/me/remove-from-library'
          : '/users/me/add-to-library';
      await api.dio.post(endpoint, data: {
        'likeables': [
          {'likeable_id': widget.track.id, 'likeable_type': 'track'}
        ],
      });
      setState(() => _isLiked = !_isLiked);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _likeLoading = false);
    }
  }
}

void _showAddToPlaylistSheet(
    BuildContext context, WidgetRef ref, Track track) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _AddToPlaylistSheet(track: track),
  );
}

class _AddToPlaylistSheet extends ConsumerWidget {
  final Track track;
  const _AddToPlaylistSheet({required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Add to playlist',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Create new playlist'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Create playlist coming soon')),
              );
            },
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Your playlists will appear here',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
