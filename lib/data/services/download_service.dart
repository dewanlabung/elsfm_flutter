import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/download.dart';
import 'hive_service.dart';

class DownloadService {
  final Dio dio;
  final int maxConcurrentDownloads;

  int _activeDownloads = 0;
  final _downloadQueue = <Download>[];
  final _statusController = StreamController<Download>.broadcast();

  DownloadService(this.dio, {this.maxConcurrentDownloads = 3});

  Stream<Download> get downloadStatusStream => _statusController.stream;

  Future<void> enqueueDownload(Download download) async {
    final box = HiveService.getDownloadsBox();
    final newDownload = download.copyWith(status: DownloadStatus.pending);
    await box.add(newDownload);
    _downloadQueue.add(newDownload);
    _processQueue();
  }

  Future<void> enqueueMultiple(List<Download> downloads) async {
    final box = HiveService.getDownloadsBox();
    for (final download in downloads) {
      final newDownload = download.copyWith(status: DownloadStatus.pending);
      await box.add(newDownload);
      _downloadQueue.add(newDownload);
    }
    _processQueue();
  }

  void _processQueue() {
    while (_activeDownloads < maxConcurrentDownloads && _downloadQueue.isNotEmpty) {
      final download = _downloadQueue.removeAt(0);
      _activeDownloads++;
      _downloadFile(download).then((_) {
        _activeDownloads--;
        _processQueue();
      }).catchError((_) {
        _activeDownloads--;
        _processQueue();
      });
    }
  }

  Future<void> _downloadFile(Download download) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final downloadDir = '${appDocDir.path}/downloads';

      // Create directory if it doesn't exist
      final dir = await Future.sync(() async {
        return await Directory(downloadDir).create(recursive: true);
      });

      final filePath = '${dir.path}/${download.trackId}.mp3';

      final box = HiveService.getDownloadsBox();
      final downloading = download.copyWith(status: DownloadStatus.downloading);

      // Find the index in box to update
      int? boxKey;
      for (int i = 0; i < box.length; i++) {
        final item = box.getAt(i);
        if (item?.id == download.id) {
          boxKey = i;
          break;
        }
      }

      if (boxKey != null) {
        await box.putAt(boxKey, downloading);
      }
      _statusController.add(downloading);

      await dio.download(
        download.downloadUrl,
        filePath,
        onReceiveProgress: (received, total) async {
          final progress = total > 0 ? received / total : 0.0;
          final updated = download.copyWith(progress: progress);

          // Update in box
          if (boxKey != null) {
            await box.putAt(boxKey, updated);
          }
          _statusController.add(updated);
        },
      );

      final completed = download.copyWith(
        status: DownloadStatus.completed,
        progress: 1.0,
        completedAt: DateTime.now(),
      );

      if (boxKey != null) {
        await box.putAt(boxKey, completed);
      }
      _statusController.add(completed);
    } catch (e) {
      final failed = download.copyWith(status: DownloadStatus.failed);
      final box = HiveService.getDownloadsBox();

      // Find and update in box
      for (int i = 0; i < box.length; i++) {
        final item = box.getAt(i);
        if (item?.id == download.id) {
          await box.putAt(i, failed);
          break;
        }
      }

      _statusController.add(failed);
    }
  }

  List<Download> getAllDownloads() {
    final box = HiveService.getDownloadsBox();
    return box.values.toList();
  }

  List<Download> getCompletedDownloads() {
    final box = HiveService.getDownloadsBox();
    return box.values.where((d) => d.status == DownloadStatus.completed).toList();
  }

  List<Download> getPendingDownloads() {
    final box = HiveService.getDownloadsBox();
    return box.values.where((d) => d.status == DownloadStatus.pending).toList();
  }

  List<Download> getDownloadingDownloads() {
    final box = HiveService.getDownloadsBox();
    return box.values.where((d) => d.status == DownloadStatus.downloading).toList();
  }

  Future<void> deleteDownload(int downloadId) async {
    final box = HiveService.getDownloadsBox();
    for (int i = 0; i < box.length; i++) {
      final item = box.getAt(i);
      if (item?.id == downloadId) {
        await box.deleteAt(i);
        break;
      }
    }
  }

  void dispose() {
    _statusController.close();
  }
}
