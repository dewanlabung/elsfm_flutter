import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/downloads_provider.dart';
import '../../../data/models/download.dart';

/// Downloads management screen
class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadsAsync = ref.watch(downloadsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloaded Songs'),
      ),
      body: downloadsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (downloads) {
          if (downloads.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download, size: 64),
                  SizedBox(height: 16),
                  Text('No downloads yet'),
                  SizedBox(height: 8),
                  Text(
                    'Downloaded songs will appear here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: downloads.length,
            itemBuilder: (context, index) {
              final download = downloads[index];
              return ListTile(
                leading: _buildLeading(download),
                title: Text(download.trackName),
                subtitle: download.status == DownloadStatus.downloading
                    ? LinearProgressIndicator(value: download.progress)
                    : Text(download.status.name),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLeading(Download download) {
    switch (download.status) {
      case DownloadStatus.downloading:
        return SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: CircularProgressIndicator(
              value: download.progress,
              strokeWidth: 2,
            ),
          ),
        );
      case DownloadStatus.completed:
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.check, color: Colors.green),
        );
      case DownloadStatus.failed:
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.red[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.error, color: Colors.red),
        );
      case DownloadStatus.pending:
        return const SizedBox(
          width: 48,
          height: 48,
          child: Icon(Icons.hourglass_empty),
        );
    }
  }
}
