import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/download_service.dart';
import 'package:elsfm/data/models/track.dart';

/// Download service provider (singleton)
final downloadServiceProvider = Provider<DownloadService>((ref) {
  return DownloadService();
});

/// Downloads list provider
final downloadsListProvider = StateNotifierProvider<DownloadsNotifier, List<DownloadStatus>>(
  (ref) => DownloadsNotifier(ref),
);

class DownloadsNotifier extends StateNotifier<List<DownloadStatus>> {
  final Ref ref;

  DownloadsNotifier(this.ref) : super([]);

  Future<void> downloadSong({
    required Track track,
    required String qualityId,
  }) async {
    final service = ref.read(downloadServiceProvider);
    try {
      await service.downloadSong(track: track, qualityId: qualityId);
      _updateDownloadsList();
    } catch (e) {
      throw Exception('Download failed: $e');
    }
  }

  Future<void> removeDownload(int trackId) async {
    final service = ref.read(downloadServiceProvider);
    try {
      await service.removeDownload(trackId);
      _updateDownloadsList();
    } catch (e) {
      throw Exception('Failed to remove download: $e');
    }
  }

  Future<void> clearAllDownloads() async {
    final service = ref.read(downloadServiceProvider);
    try {
      await service.clearAllDownloads();
      state = [];
    } catch (e) {
      throw Exception('Failed to clear downloads: $e');
    }
  }

  void _updateDownloadsList() {
    final service = ref.read(downloadServiceProvider);
    state = service.getDownloads();
  }

  void refreshDownloads() {
    _updateDownloadsList();
  }
}

/// Download status provider (for watching specific download)
final downloadStatusProvider = StateProvider.family<DownloadStatus?, int>((ref, trackId) {
  final service = ref.watch(downloadServiceProvider);
  return service.getDownloadStatus(trackId);
});

/// Total download size provider
final totalDownloadSizeProvider = Provider<int>((ref) {
  final service = ref.watch(downloadServiceProvider);
  return service.getTotalDownloadSize();
});

// DownloadStatus is defined in download_service.dart and re-exported via the import above.
