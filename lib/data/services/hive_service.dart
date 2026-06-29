import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/download.dart';
import 'cache_service.dart';

class HiveService {
  static const String downloadsBoxName = 'downloads';
  static const String tracksBoxName = 'cache_tracks';
  static const String albumsBoxName = 'cache_albums';
  static const String playlistsBoxName = 'cache_playlists';

  static Future<void> init() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocDir.path);

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(DownloadAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(DownloadStatusAdapter());
    }

    await Future.wait([
      Hive.openBox<Download>(downloadsBoxName),
      Hive.openBox<String>(tracksBoxName),
      Hive.openBox<String>(albumsBoxName),
      Hive.openBox<String>(playlistsBoxName),
    ]);
  }

  static Box<Download> getDownloadsBox() => Hive.box<Download>(downloadsBoxName);

  /// Returns a [CacheService] scoped to the tracks box.
  static CacheService getTrackCache() =>
      CacheService(Hive.box<String>(tracksBoxName));

  /// Returns a [CacheService] scoped to the albums box.
  static CacheService getAlbumCache() =>
      CacheService(Hive.box<String>(albumsBoxName));

  /// Returns a [CacheService] scoped to the playlists box.
  static CacheService getPlaylistCache() =>
      CacheService(Hive.box<String>(playlistsBoxName));

  static Future<void> close() async {
    await Hive.close();
  }
}
