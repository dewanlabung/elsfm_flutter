import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/track.dart';
import '../../../data/models/playlist.dart';
import '../../../data/models/album.dart';
import '../../../data/providers/api_client_provider.dart';
import '../../../config/app_config.dart';

// The channel ID to use as the home screen.
// Change this value in admin → the app picks it up on next refresh.
const int homeChannelId = 5;

class ChannelContent {
  final String channelName;
  final String? channelDescription;
  final String? channelImage;
  final List<Track> tracks;
  final List<Playlist> playlists;
  final List<Album> albums;

  const ChannelContent({
    required this.channelName,
    required this.channelDescription,
    required this.channelImage,
    required this.tracks,
    required this.playlists,
    required this.albums,
  });
}

final channelHomeProvider =
    FutureProvider.family<ChannelContent, int>((ref, channelId) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.getChannel(channelId);
  final data = response.data;

  final channelName = data['name'] as String? ?? 'Channel $channelId';
  final channelDesc = data['description'] as String?;
  final channelImg = _resolveImage(data['image'] as String?);

  final contentList = data['content'] as List<dynamic>? ?? [];

  final tracks = <Track>[];
  final playlists = <Playlist>[];
  final albums = <Album>[];

  for (final item in contentList) {
    if (item is! Map<String, dynamic>) continue;
    final type = item['model_type'] as String? ?? '';
    try {
      if (type == 'track') {
        tracks.add(Track.fromJson(item));
      } else if (type == 'playlist') {
        playlists.add(Playlist.fromJson(item));
      } else if (type == 'album') {
        albums.add(Album.fromJson(item));
      }
    } catch (_) {}
  }

  return ChannelContent(
    channelName: channelName,
    channelDescription: channelDesc,
    channelImage: channelImg,
    tracks: tracks,
    playlists: playlists,
    albums: albums,
  );
});

String? _resolveImage(String? img) {
  if (img == null || img.isEmpty) return null;
  if (img.startsWith('http')) return img;
  return '${AppConfig.webBaseUrl}/$img';
}
