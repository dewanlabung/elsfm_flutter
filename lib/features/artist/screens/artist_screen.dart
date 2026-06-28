import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_config.dart';
import '../providers/artist_provider.dart';
import '../../player/providers/player_notifier.dart';

class ArtistScreen extends ConsumerStatefulWidget {
  final int artistId;

  const ArtistScreen({super.key, required this.artistId});

  @override
  ConsumerState<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends ConsumerState<ArtistScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(selectedArtistIdProvider.notifier).state = widget.artistId;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String? _resolveImage(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    return '${AppConfig.webBaseUrl}/$raw';
  }

  String _fmt(Duration d) {
    final m = d.inSeconds ~/ 60;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final artistAsync = ref.watch(artistProvider);
    final tracksAsync = ref.watch(artistTracksProvider);
    final albumsAsync = ref.watch(artistAlbumsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: artistAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (artist) {
          final imageUrl = _resolveImage(artist['image_small'] as String? ??
              artist['image'] as String?);
          final artistName = (artist['name'] as String?) ?? 'Artist';
          final views = artist['views']?.toString() ?? '0';

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                forceElevated: innerBoxIsScrolled,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    artistName,
                    style: const TextStyle(
                      shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                    ),
                  ),
                  background: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _ArtistPlaceholder(name: artistName),
                        )
                      : _ArtistPlaceholder(name: artistName),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      Icon(Icons.headphones,
                          size: 16, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      Text('$views plays',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Tracks'),
                      Tab(text: 'Albums'),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                // ── Tracks tab ──────────────────────────────────────────────
                tracksAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                  data: (tracks) {
                    if (tracks.isEmpty) {
                      return const Center(child: Text('No tracks'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: tracks.length,
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        final imgUrl = _resolveImage(track.image);
                        return ListTile(
                          leading: imgUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    imgUrl,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.music_note,
                                        size: 28),
                                  ),
                                )
                              : const Icon(Icons.music_note, size: 28),
                          title: Text(
                            track.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            track.artists.map((a) => a.name).join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            _fmt(track.duration),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          onTap: () {
                            ref
                                .read(playerProvider.notifier)
                                .setQueue(tracks, startIndex: index);
                            context.push('/now-playing');
                          },
                        );
                      },
                    );
                  },
                ),

                // ── Albums tab ──────────────────────────────────────────────
                albumsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                  data: (albums) {
                    if (albums.isEmpty) {
                      return const Center(child: Text('No albums'));
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: albums.length,
                      itemBuilder: (context, index) {
                        final album = albums[index];
                        final albumImg = _resolveImage(album.image);
                        return GestureDetector(
                          onTap: () => context.push('/album/${album.id}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: albumImg != null
                                      ? Image.network(
                                          albumImg,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _AlbumPlaceholder(
                                                  name: album.name),
                                        )
                                      : _AlbumPlaceholder(name: album.name),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                album.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13),
                              ),
                              if (album.releaseYear != null)
                                Text(
                                  '${album.releaseYear}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}

class _ArtistPlaceholder extends StatelessWidget {
  final String name;
  const _ArtistPlaceholder({required this.name});

  Color get _color {
    final hue = (name.codeUnits.fold(0, (a, b) => a + b) % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.45, 0.3).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _color,
      child: const Center(
        child: Icon(Icons.person, size: 80, color: Colors.white54),
      ),
    );
  }
}

class _AlbumPlaceholder extends StatelessWidget {
  final String name;
  const _AlbumPlaceholder({required this.name});

  Color get _color {
    final hue = (name.codeUnits.fold(0, (a, b) => a + b) % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.4, 0.3).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _color,
      child: const Center(
        child: Icon(Icons.album, size: 40, color: Colors.white54),
      ),
    );
  }
}
