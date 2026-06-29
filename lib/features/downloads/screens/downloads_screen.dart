import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/download_provider.dart';
import '../services/download_service.dart';

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<DownloadStatus> _filter(List<DownloadStatus> all, int tab) {
    switch (tab) {
      case 0:
        return all;
      case 1:
        return all.where((d) => d.isDownloading).toList();
      case 2:
        return all.where((d) => d.isComplete).toList();
      case 3:
        return all.where((d) => d.isFailed).toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(downloadsListProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go('/search'),
          ),
          if (all.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'clear') _showClearConfirmation(context, ref);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'clear', child: Text('Clear all')),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Running'),
            Tab(text: 'Completed'),
            Tab(text: 'Interrupted'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(4, (tab) {
          final items = _filter(all, tab);
          if (items.isEmpty) {
            return _EmptyTab(tab: tab);
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: colorScheme.outlineVariant),
            itemBuilder: (context, i) =>
                _DownloadTile(download: items[i], ref: ref),
          );
        }),
      ),
    );
  }

  void _showClearConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Downloads'),
        content: const Text('Delete all downloaded songs?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(downloadsListProvider.notifier).clearAllDownloads();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _DownloadTile extends StatelessWidget {
  final DownloadStatus download;
  final WidgetRef ref;
  const _DownloadTile({required this.download, required this.ref});

  String _fmtSize(int? bytes) {
    if (bytes == null || bytes == 0) return '';
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Stack(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: colorScheme.surfaceContainerHighest,
                ),
                child: const Icon(Icons.music_note, size: 32, color: Colors.grey),
              ),
              if (download.isDownloading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.black45,
                    ),
                    child: Center(
                      child: Text(
                        '${download.progress}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  download.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                if (download.isDownloading) ...[
                  LinearProgressIndicator(
                    value: download.progress / 100,
                    minHeight: 3,
                    backgroundColor: colorScheme.outlineVariant,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 4),
                  Text('Downloading ${download.progress}%',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ] else ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('MP3',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        download.isComplete
                            ? 'DOWNLOAD COMPLETE'
                            : download.isPending
                                ? 'PENDING'
                                : 'INTERRUPTED',
                        style: TextStyle(
                          fontSize: 12,
                          color: download.isComplete
                              ? Colors.grey
                              : download.isPending
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  if (_fmtSize(download.fileSizeBytes).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(_fmtSize(download.fileSizeBytes),
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ],
              ],
            ),
          ),
          // Status icon
          Column(
            children: [
              if (download.isComplete)
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 18),
                )
              else if (download.isFailed)
                const Icon(Icons.error, color: Colors.red, size: 28),
              const SizedBox(height: 8),
              if (download.isComplete)
                GestureDetector(
                  onTap: () => ref
                      .read(downloadsListProvider.notifier)
                      .removeDownload(download.trackId),
                  child: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  final int tab;
  const _EmptyTab({required this.tab});

  static const _msgs = [
    ('No downloads yet', 'Songs you download will appear here'),
    ('No active downloads', 'Downloads in progress will show here'),
    ('No completed downloads', 'Finished downloads will show here'),
    ('No interrupted downloads', 'Failed downloads will show here'),
  ];

  @override
  Widget build(BuildContext context) {
    final (title, hint) = _msgs[tab];
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.download_outlined, size: 72,
              color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(hint,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.outline, fontSize: 13)),
        ],
      ),
    );
  }
}
