import 'package:elsfm/data/repositories/playlist_repository.dart';
import 'package:elsfm/data/models/playlist_v2.dart';
import 'package:elsfm/data/models/track.dart';

/// Playlist service for CRUD operations
class PlaylistService {
  final PlaylistRepository repository;

  PlaylistService({required this.repository});

  /// Create a new playlist
  Future<PlaylistV2> createPlaylist({
    required String name,
    String? description,
  }) async {
    try {
      return await repository.createPlaylist(
        name: name,
        description: description,
      );
    } catch (e) {
      throw PlaylistException('Failed to create playlist: $e');
    }
  }

  /// Get all user playlists
  Future<List<PlaylistV2>> getUserPlaylists() async {
    try {
      return await repository.getUserPlaylists();
    } catch (e) {
      throw PlaylistException('Failed to load playlists: $e');
    }
  }

  /// Get a specific playlist
  Future<PlaylistV2> getPlaylist(int playlistId) async {
    try {
      return await repository.getPlaylist(playlistId);
    } catch (e) {
      throw PlaylistException('Failed to load playlist: $e');
    }
  }

  /// Update playlist
  Future<PlaylistV2> updatePlaylist({
    required int playlistId,
    String? name,
    String? description,
  }) async {
    try {
      return await repository.updatePlaylist(
        playlistId: playlistId,
        name: name,
        description: description,
      );
    } catch (e) {
      throw PlaylistException('Failed to update playlist: $e');
    }
  }

  /// Delete playlist
  Future<void> deletePlaylist(int playlistId) async {
    try {
      return await repository.deletePlaylist(playlistId);
    } catch (e) {
      throw PlaylistException('Failed to delete playlist: $e');
    }
  }

  /// Add song to playlist
  Future<PlaylistV2> addSong({
    required int playlistId,
    required int trackId,
  }) async {
    try {
      return await repository.addSongToPlaylist(
        playlistId: playlistId,
        trackId: trackId,
      );
    } catch (e) {
      throw PlaylistException('Failed to add song: $e');
    }
  }

  /// Remove song from playlist
  Future<PlaylistV2> removeSong({
    required int playlistId,
    required int trackId,
  }) async {
    try {
      return await repository.removeSongFromPlaylist(
        playlistId: playlistId,
        trackId: trackId,
      );
    } catch (e) {
      throw PlaylistException('Failed to remove song: $e');
    }
  }

  /// Reorder song in playlist
  Future<PlaylistV2> reorderSong({
    required int playlistId,
    required int trackId,
    required int newPosition,
  }) async {
    try {
      return await repository.reorderSongInPlaylist(
        playlistId: playlistId,
        trackId: trackId,
        newPosition: newPosition,
      );
    } catch (e) {
      throw PlaylistException('Failed to reorder song: $e');
    }
  }

  /// Bulk add songs
  Future<PlaylistV2> addSongs({
    required int playlistId,
    required List<int> trackIds,
  }) async {
    try {
      return await repository.addSongsToPlaylist(
        playlistId: playlistId,
        trackIds: trackIds,
      );
    } catch (e) {
      throw PlaylistException('Failed to add songs: $e');
    }
  }
}

/// Playlist exception
class PlaylistException implements Exception {
  final String message;

  PlaylistException(this.message);

  @override
  String toString() => 'PlaylistException: $message';
}
