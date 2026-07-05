import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:elsfm/data/models/track.dart';

class DownloadService {
  final Dio _dio;
  final Map<int, DownloadStatus> _downloads = {};

  DownloadService(this._dio);

  Future<String> _downloadsDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/elsfm_downloads');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  String _filePath(String dir, int trackId) => '$dir/$trackId.mp3';

  Future<void> downloadSong({
    required Track track,
    required String qualityId,
  }) async {
    _downloads[track.id] = DownloadStatus(
      trackId: track.id,
      title: track.name,
      progress: 0,
      isDownloading: true,
    );

    try {
      final dir = await _downloadsDir();
      final filePath = _filePath(dir, track.id);

      await _dio.download(
        '/tracks/${track.id}/stream',
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final pct = (received / total * 100).round().clamp(0, 99);
            _downloads[track.id] = DownloadStatus(
              trackId: track.id,
              title: track.name,
              progress: pct,
              isDownloading: true,
            );
          }
        },
      );

      final fileSize = await File(filePath).length();
      _downloads[track.id] = DownloadStatus(
        trackId: track.id,
        title: track.name,
        progress: 100,
        isDownloading: false,
        isComplete: true,
        fileSizeBytes: fileSize,
      );
    } catch (e) {
      _downloads[track.id] = DownloadStatus(
        trackId: track.id,
        title: track.name,
        progress: 0,
        isDownloading: false,
        isFailed: true,
      );
      throw DownloadException('Download failed: $e');
    }
  }

  Future<void> removeDownload(int trackId) async {
    try {
      final dir = await _downloadsDir();
      final file = File(_filePath(dir, trackId));
      if (await file.exists()) await file.delete();
      _downloads.remove(trackId);
    } catch (e) {
      throw DownloadException('Failed to remove download: $e');
    }
  }

  List<DownloadStatus> getDownloads() => _downloads.values.toList();

  DownloadStatus? getDownloadStatus(int trackId) => _downloads[trackId];

  Future<void> clearAllDownloads() async {
    try {
      final dir = await _downloadsDir();
      for (final id in _downloads.keys) {
        final file = File(_filePath(dir, id));
        if (await file.exists()) await file.delete();
      }
      _downloads.clear();
    } catch (e) {
      throw DownloadException('Failed to clear downloads: $e');
    }
  }

  int getTotalDownloadSize() {
    return _downloads.values
        .where((d) => d.isComplete)
        .fold(0, (sum, d) => sum + (d.fileSizeBytes ?? 0));
  }

  /// Returns the local file path if the track is downloaded, otherwise null.
  Future<String?> getLocalFilePath(int trackId) async {
    final status = _downloads[trackId];
    if (status == null || !status.isComplete) return null;
    final dir = await _downloadsDir();
    final path = _filePath(dir, trackId);
    return await File(path).exists() ? path : null;
  }
}

class DownloadStatus {
  final int trackId;
  final String title;
  final int progress;
  final bool isDownloading;
  final bool isComplete;
  final bool isFailed;
  final int? fileSizeBytes;
  final DateTime downloadedAt;

  DownloadStatus({
    required this.trackId,
    required this.title,
    required this.progress,
    required this.isDownloading,
    this.isComplete = false,
    this.isFailed = false,
    this.fileSizeBytes,
    DateTime? downloadedAt,
  }) : downloadedAt = downloadedAt ?? DateTime.now();

  bool get isPending => !isComplete && !isDownloading && !isFailed;
}

class DownloadException implements Exception {
  final String message;
  DownloadException(this.message);

  @override
  String toString() => 'DownloadException: $message';
}
