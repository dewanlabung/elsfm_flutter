import 'package:elsfm/data/repositories/user_library_repository.dart';
import 'package:elsfm/data/models/user_library.dart';
import 'package:elsfm/data/models/track.dart';

/// User library service (favorites + history)
class LibraryService {
  final UserLibraryRepository repository;

  LibraryService({required this.repository});

  Future<UserLibrary> getLibrary() async {
    try {
      return await repository.getUserLibrary();
    } catch (e) {
      throw LibraryException('Failed to load library: $e');
    }
  }

  Future<List<Track>> getFavorites() async {
    try {
      return await repository.getFavorites();
    } catch (e) {
      throw LibraryException('Failed to load favorites: $e');
    }
  }

  Future<void> addFavorite(int trackId) async {
    try {
      return await repository.addFavorite(trackId);
    } catch (e) {
      throw LibraryException('Failed to add favorite: $e');
    }
  }

  Future<void> removeFavorite(int trackId) async {
    try {
      return await repository.removeFavorite(trackId);
    } catch (e) {
      throw LibraryException('Failed to remove favorite: $e');
    }
  }

  Future<List<Track>> getHistory() async {
    try {
      return await repository.getHistory();
    } catch (e) {
      throw LibraryException('Failed to load history: $e');
    }
  }

  Future<void> logPlay(int trackId) async {
    try {
      return await repository.logPlay(trackId: trackId);
    } catch (e) {
      throw LibraryException('Failed to log play: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      return await repository.clearHistory();
    } catch (e) {
      throw LibraryException('Failed to clear history: $e');
    }
  }

  Future<List<Track>> getTopTracks({String period = 'month'}) async {
    try {
      return await repository.getTopTracks(period: period);
    } catch (e) {
      throw LibraryException('Failed to load top tracks: $e');
    }
  }
}

class LibraryException implements Exception {
  final String message;
  LibraryException(this.message);

  @override
  String toString() => 'LibraryException: $message';
}
