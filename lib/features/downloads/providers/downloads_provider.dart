import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/download_service.dart';
import '../../../data/services/hive_service.dart';
import '../../../data/providers/http_client_provider.dart';
import '../../../data/models/download.dart';

final downloadServiceProvider = FutureProvider<DownloadService>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return DownloadService(dio);
});

final downloadsProvider = StreamProvider<List<Download>>((ref) async* {
  final downloadService = await ref.watch(downloadServiceProvider.future);
  final box = HiveService.getDownloadsBox();
  yield box.values.toList();

  await for (final _ in downloadService.downloadStatusStream) {
    yield box.values.toList();
  }
});

final completedDownloadsProvider = FutureProvider<List<Download>>((ref) async {
  final downloadService = await ref.watch(downloadServiceProvider.future);
  return downloadService.getCompletedDownloads();
});

final pendingDownloadsProvider = FutureProvider<List<Download>>((ref) async {
  final downloadService = await ref.watch(downloadServiceProvider.future);
  return downloadService.getPendingDownloads();
});

final downloadingDownloadsProvider = FutureProvider<List<Download>>((ref) async {
  final downloadService = await ref.watch(downloadServiceProvider.future);
  return downloadService.getDownloadingDownloads();
});
