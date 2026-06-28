import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/track.dart';
import '../../../data/models/playlist.dart';
import '../../../data/models/album.dart';
import '../../../config/app_config.dart';
import '../providers/channel_home_provider.dart';
import '../../player/providers/player_notifier.dart';

String _fmtDuration(Duration d) {
  final m = d.inSeconds ~/ 60;
  final s = d.inSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelAsync = ref.watch(channelHomeProvider(homeChannelId));

    return Scaffold(
      appBar: AppBar(
        title: channelAsync.maybeWhen(
          data: (ch) => Text(ch.channelName),
          orElse: () => const Text('ELSFM'),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.library_music_outlined),
            onPressed: () => context.go('/library'),
            tooltip: 'Library',
          ),
        ],
      ),
      body: channelAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Could not load channel',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '$err',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.invalidate(channelHomeProvider(homeChannelId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (channel) => RefreshIndicator(
          // Pull down to re-fetch — admin changes reflect immediately
          onRefresh: () async =>
              ref.invalidate(channelHomeProvider(homeChannelId)),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Channel banner
                if (channel.channelImage != null)
                  _ChannelBanner(
                    imageUrl: channel.channelImage!,
                    description: channel.channelDescription,
                  ),

                // Playlists section
                if (channel.playlists.isNotEmpty) ...[
                  _SectionHeader(title: 'Playlists'),
                  _PlaylistRow(playlists: channel.playlists),
                  const SizedBox(height: 8),
                ],

                // Albums section
                if (channel.albums.isNotEmpty) ...[
                  _SectionHeader(title: 'Albums'),
                  _AlbumRow(albums: channel.albums),
                  const SizedBox(height: 8),
                ],

                // Tracks section
                if (channel.tracks.isNotEmpty) ...[
                  _SectionHeader(title: 'Songs'),
                  _TrackList(tracks: channel.tracks),
                ],

                // Empty state when channel has no content yet
                if (channel.tracks.isEmpty &&
                    channel.playlists.isEmpty &&
                    channel.albums.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.music_off,
                              size: 64,
                              color: Colors.grey.withOpacity(0.4)),
                          const SizedBox(height: 16),
                          Text(
                            'No content in "${channel.channelName}" yet',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add songs in admin → Channels',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Channel banner ────────────────────────────────────────────────────────────

class _ChannelBanner extends StatelessWidget {
  final String imageUrl;
  final String? description;

  const _ChannelBanner({required this.imageUrl, this.description});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 180,
          width: double.infinity,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 180,
              color: Theme.of(context).colorScheme.primaryContainer,
              child: const Icon(Icons.music_note, size: 64),
            ),
          ),
        ),
        if (description != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
              child: Text(
                description!,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ── Playlists ────────────────────────────────────────────────────────────────

class _PlaylistRow extends StatelessWidget {
  final List<Playlist> playlists;

  const _PlaylistRow({required this.playlists});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: playlists.length,
        itemBuilder: (_, i) => _PlaylistCard(playlist: playlists[i]),
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final Playlist playlist;

  const _PlaylistCard({required this.playlist});

  Color get _color {
    final hue =
        (playlist.name.codeUnits.fold(0, (a, b) => a + b) % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.4, 0.35).toColor();
  }

  String? get _img {
    final img = playlist.image;
    if (img == null || img.isEmpty) return null;
    if (img.startsWith('http')) return img;
    return '${AppConfig.webBaseUrl}/$img';
  }

  @override
  Widget build(BuildContext context) {
    const size = 120.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _img != null
                ? Image.network(_img!, width: size, height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _ColorBox(color: _color, size: size))
                : _ColorBox(color: _color, size: size),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: size,
            child: Text(playlist.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall),
          ),
        ],
      ),
    );
  }
}

// ── Albums ───────────────────────────────────────────────────────────────────

class _AlbumRow extends StatelessWidget {
  final List<Album> albums;

  const _AlbumRow({required this.albums});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: albums.length,
        itemBuilder: (_, i) => _AlbumCard(album: albums[i]),
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final Album album;

  const _AlbumCard({required this.album});

  String? get _img {
    final img = album.image;
    if (img == null || img.isEmpty) return null;
    if (img.startsWith('http')) return img;
    return '${AppConfig.webBaseUrl}/$img';
  }

  @override
  Widget build(BuildContext context) {
    const size = 120.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _img != null
                ? Image.network(_img!, width: size, height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _ColorBox(color: Colors.blueGrey, size: size))
                : _ColorBox(color: Colors.blueGrey, size: size),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: size,
            child: Text(album.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall),
          ),
        ],
      ),
    );
  }
}

// ── Tracks ───────────────────────────────────────────────────────────────────

class _TrackList extends ConsumerWidget {
  final List<Track> tracks;

  const _TrackList({required this.tracks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tracks.length,
      itemBuilder: (_, i) {
        final track = tracks[i];
        final img = track.image;
        final imageUrl = (img != null && img.isNotEmpty)
            ? (img.startsWith('http') ? img : '${AppConfig.webBaseUrl}/$img')
            : null;
        final artists = track.artists.map((a) => a.name).join(', ');

        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: imageUrl != null
                ? Image.network(imageUrl,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _NumberBox(index: i + 1, context: context))
                : _NumberBox(index: i + 1, context: context),
          ),
          title: Text(track.name,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: artists.isNotEmpty
              ? Text(artists, maxLines: 1, overflow: TextOverflow.ellipsis)
              : null,
          trailing: Text(
            _fmtDuration(track.duration),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          onTap: () => ref.read(playerProvider.notifier).playTrack(track),
        );
      },
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _ColorBox extends StatelessWidget {
  final Color color;
  final double size;

  const _ColorBox({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: color,
      child: const Center(
          child: Icon(Icons.music_note, color: Colors.white70, size: 40)),
    );
  }
}

class _NumberBox extends StatelessWidget {
  final int index;
  final BuildContext context;

  const _NumberBox({required this.index, required this.context});

  @override
  Widget build(BuildContext _) {
    return Container(
      width: 44,
      height: 44,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
          child: Text('$index',
              style: Theme.of(context).textTheme.labelSmall)),
    );
  }
}
