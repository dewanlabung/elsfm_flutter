import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/download_provider.dart';
import '../services/download_service.dart';

/// Downloads management screen
class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(downloadsListProvider);
    final totalSize = ref.watch(totalDownloadSizeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloaded Songs'),
        actions: downloads.isNotEmpty
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: () => _showClearConfirmation(context, ref),
                  tooltip: 'Clear all downloads',
                ),
              ]
            : [],
      ),
      body: downloads.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.download, size: 64),
                  const SizedBox(height: 16),
                  const Text('No downloads yet'),
                  const SizedBox(height: 8),
                  const Text(
                    'Downloaded songs will appear here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${downloads.length} songs',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(totalSize / (1024 * 1024)).toStringAsFixed(2)} MB',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: downloads.length,
                    itemBuilder: (context, index) {
                      final download = downloads[index];
                      return ListTile(
                        leading: _buildLeading(download),
                        title: Text(download.title),
                        subtitle: download.isDownloading
                            ? LinearProgressIndicator(
                                value: download.progress / 100,
                              )
                            : Text('${download.progress}% downloaded'),
                        trailing: download.isComplete
                            ? IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  ref
                                      .read(downloadsListProvider.notifier)
                                      .removeDownload(download.trackId);
                                },
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLeading(DownloadStatus download) {
    if (download.isDownloading) {
      return SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: CircularProgressIndicator(
            value: download.progress / 100,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (download.isComplete) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.green[100],
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.check, color: Colors.green),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.red[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.error, color: Colors.red),
    );
  }

  void _showClearConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Downloads'),
        content: const Text('This will delete all downloaded songs. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(downloadsListProvider.notifier).clearAllDownloads();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

// DownloadStatus is defined in download_service.dart.
