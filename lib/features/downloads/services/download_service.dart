import 'package:elsfm/data/models/track.dart';

/// Download service for offline playback
class DownloadService {
  // Local storage management
  final Map<int, DownloadStatus> _downloads = {};

  /// Start downloading a song
  Future<void> downloadSong({
    required Track track,
    required String qualityId,
  }) async {
    try {
      _downloads[track.id] = DownloadStatus(
        trackId: track.id,
        title: track.name,
        progress: 0,
        isDownloading: true,
      );

      // Simulate download progress
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        _downloads[track.id] = DownloadStatus(
          trackId: track.id,
          title: track.name,
          progress: i,
          isDownloading: i < 100,
        );
      }

      _downloads[track.id] = DownloadStatus(
        trackId: track.id,
        title: track.name,
        progress: 100,
        isDownloading: false,
        isComplete: true,
      );
    } catch (e) {
      throw DownloadException('Download failed: $e');
    }
  }

  /// Remove downloaded song
  Future<void> removeDownload(int trackId) async {
    try {
      _downloads.remove(trackId);
    } catch (e) {
      throw DownloadException('Failed to remove download: $e');
    }
  }

  /// Get all downloads
  List<DownloadStatus> getDownloads() => _downloads.values.toList();

  /// Get download status
  DownloadStatus? getDownloadStatus(int trackId) => _downloads[trackId];

  /// Clear all downloads
  Future<void> clearAllDownloads() async {
    try {
      _downloads.clear();
    } catch (e) {
      throw DownloadException('Failed to clear downloads: $e');
    }
  }

  /// Get total download size
  int getTotalDownloadSize() {
    return _downloads.values
        .where((d) => d.isComplete)
        .fold(0, (sum, d) => sum + (d.fileSizeBytes ?? 0));
  }
}

/// Download status tracking
class DownloadStatus {
  final int trackId;
  final String title;
  final int progress; // 0-100
  final bool isDownloading;
  final bool isComplete;
  final int? fileSizeBytes;
  final DateTime downloadedAt;

  DownloadStatus({
    required this.trackId,
    required this.title,
    required this.progress,
    required this.isDownloading,
    this.isComplete = false,
    this.fileSizeBytes,
    DateTime? downloadedAt,
  }) : downloadedAt = downloadedAt ?? DateTime.now();

  bool get isPending => !isComplete && !isDownloading;
  bool get isFailed => progress < 100 && !isDownloading && !isComplete;
}

class DownloadException implements Exception {
  final String message;
  DownloadException(this.message);

  @override
  String toString() => 'DownloadException: $message';
}
