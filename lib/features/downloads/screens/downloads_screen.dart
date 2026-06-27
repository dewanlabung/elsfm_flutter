import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/download.dart';
import '../providers/downloads_provider.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadsAsync = ref.watch(downloadsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        elevation: 0,
      ),
      body: downloadsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
        data: (downloads) {
          if (downloads.isEmpty) {
            return const Center(child: Text('No downloads yet'));
          }

          final downloading = downloads
              .where((d) => d.status == DownloadStatus.downloading)
              .toList();
          final completed = downloads
              .where((d) => d.status == DownloadStatus.completed)
              .toList();
          final failed = downloads
              .where((d) => d.status == DownloadStatus.failed)
              .toList();
          final pending = downloads
              .where((d) => d.status == DownloadStatus.pending)
              .toList();

          return ListView(
            children: [
              if (downloading.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Downloading (${downloading.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ...downloading.map((d) => _buildDownloadItem(context, ref, d)),
              ],
              if (pending.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Queued (${pending.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ...pending.map((d) => _buildDownloadItem(context, ref, d)),
              ],
              if (failed.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Failed (${failed.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ...failed.map((d) => _buildDownloadItem(context, ref, d)),
              ],
              if (completed.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Downloaded (${completed.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ...completed.map((d) => _buildDownloadItem(context, ref, d)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildDownloadItem(
    BuildContext context,
    WidgetRef ref,
    Download download,
  ) {
    final isDownloading = download.status == DownloadStatus.downloading;
    final isCompleted = download.status == DownloadStatus.completed;
    final isFailed = download.status == DownloadStatus.failed;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      download.trackName,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isDownloading)
                    Text(
                      '${(download.progress * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  if (isFailed)
                    const Icon(Icons.error, color: Colors.red, size: 20),
                  if (isCompleted)
                    const Icon(Icons.check_circle, color: Color(0xFF1DB954), size: 20),
                ],
              ),
              const SizedBox(height: 8),
              if (isDownloading)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: download.progress,
                    minHeight: 4,
                    backgroundColor: Colors.grey[800],
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
                  ),
                )
              else if (isFailed)
                Text(
                  'Download failed',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.red,
                      ),
                )
              else if (isCompleted)
                Text(
                  'Completed on ${_formatDate(download.completedAt)}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isCompleted)
                    TextButton(
                      onPressed: () {},
                      child: const Text('Play'),
                    ),
                  TextButton(
                    onPressed: () => _deleteDownload(context, ref, download),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteDownload(
    BuildContext context,
    WidgetRef ref,
    Download download,
  ) async {
    final downloadService = await ref.read(downloadServiceProvider.future);
    await downloadService.deleteDownload(download.id);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.month}/${date.day}/${date.year}';
  }
}
