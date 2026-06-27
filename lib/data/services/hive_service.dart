import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/download.dart';

class HiveService {
  static const String downloadsBoxName = 'downloads';

  static Future<void> init() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocDir.path);

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(DownloadAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(DownloadStatusAdapter());
    }

    await Hive.openBox<Download>(downloadsBoxName);
  }

  static Box<Download> getDownloadsBox() {
    return Hive.box<Download>(downloadsBoxName);
  }

  static Future<void> close() async {
    await Hive.close();
  }
}
