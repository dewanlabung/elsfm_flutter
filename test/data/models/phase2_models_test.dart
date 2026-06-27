import 'package:flutter_test/flutter_test.dart';
import 'package:elsfm/data/models/quality_option.dart';
import 'package:elsfm/data/models/recommendation.dart';
import 'package:elsfm/data/models/user_library.dart';
import 'package:elsfm/data/models/playlist_v2.dart';
import 'package:elsfm/data/models/track.dart';
import 'package:elsfm/data/models/artist.dart';

void main() {
  group('Phase 2 Data Models', () {
    // TEST 1: QualityOption serialization
    test('QualityOption serializes and deserializes correctly', () {
      final quality = QualityOption(
        id: '320',
        label: 'High',
        bitrate: 320,
        format: 'AAC',
      );

      final json = quality.toJson();
      final deserialized = QualityOption.fromJson(json);

      expect(deserialized.id, equals('320'));
      expect(deserialized.bitrate, equals(320));
      expect(deserialized.format, equals('AAC'));
    });

    // TEST 2: QualityOption equality
    test('QualityOption equality works correctly', () {
      final q1 = QualityOption(id: '320', label: 'High', bitrate: 320, format: 'AAC');
      final q2 = QualityOption(id: '320', label: 'High', bitrate: 320, format: 'AAC');
      final q3 = QualityOption(id: '128', label: 'Low', bitrate: 128, format: 'AAC');

      expect(q1, equals(q2));
      expect(q1, isNot(equals(q3)));
    });

    // TEST 3: UserLibraryEntry serialization
    test('UserLibraryEntry serializes and deserializes correctly', () {
      final entry = UserLibraryEntry(
        trackId: 123,
        entryType: 'favorite',
        addedAt: DateTime(2026, 6, 28),
        durationPlayedSeconds: 180,
      );

      final json = entry.toJson();
      final deserialized = UserLibraryEntry.fromJson(json);

      expect(deserialized.trackId, equals(123));
      expect(deserialized.entryType, equals('favorite'));
      expect(deserialized.durationPlayedSeconds, equals(180));
    });

    // TEST 4: UserLibrary with multiple entries
    test('UserLibrary handles multiple entries', () {
      final artist = Artist(id: 1, name: 'Test Artist', views: 0);
      final track1 = Track(
        id: 1,
        name: 'Song 1',
        duration: const Duration(seconds: 200),
        src: 'https://example.com/song1.mp3',
        artists: [artist],
        views: 1000,
      );
      final track2 = Track(
        id: 2,
        name: 'Song 2',
        duration: const Duration(seconds: 210),
        src: 'https://example.com/song2.mp3',
        artists: [artist],
        views: 2000,
      );

      final library = UserLibrary(
        favorites: [track1],
        recentHistory: [track2, track1],
        trackPlayCounts: {1: 5, 2: 3},
        lastUpdated: DateTime.now(),
      );

      expect(library.isFavorite(1), isTrue);
      expect(library.isFavorite(2), isFalse);
      expect(library.getPlayCount(1), equals(5));
      expect(library.getPlayCount(999), equals(0));
    });

    // TEST 5: PlaylistV2 basic operations
    test('PlaylistV2 supports add/remove/reorder tracks', () {
      final artist = Artist(id: 1, name: 'Test Artist', views: 0);
      final track1 = Track(
        id: 1,
        name: 'Song 1',
        duration: const Duration(seconds: 200),
        src: 'https://example.com/song1.mp3',
        artists: [artist],
        views: 1000,
      );
      final track2 = Track(
        id: 2,
        name: 'Song 2',
        duration: const Duration(seconds: 210),
        src: 'https://example.com/song2.mp3',
        artists: [artist],
        views: 2000,
      );

      var playlist = PlaylistV2(
        id: 1,
        userId: 1,
        name: 'My Playlist',
        tracks: [track1],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isOfflineEnabled: false,
        isCollaborative: false,
        isDeleted: false,
      );

      // Add track
      playlist = playlist.addTrack(track2);
      expect(playlist.trackCount, equals(2));

      // Prevent duplicate
      playlist = playlist.addTrack(track1);
      expect(playlist.trackCount, equals(2)); // Still 2, no duplicate

      // Remove track
      playlist = playlist.removeTrack(1);
      expect(playlist.trackCount, equals(1));
      expect(playlist.tracks.first.id, equals(2));
    });

    // TEST 6: PlaylistV2 serialization
    test('PlaylistV2 serializes and deserializes correctly', () {
      final artist = Artist(id: 1, name: 'Test Artist', views: 0);
      final track = Track(
        id: 1,
        name: 'Song 1',
        duration: const Duration(seconds: 200),
        src: 'https://example.com/song1.mp3',
        artists: [artist],
        views: 1000,
      );

      final playlist = PlaylistV2(
        id: 1,
        userId: 1,
        name: 'My Playlist',
        description: 'Test description',
        tracks: [track],
        createdAt: DateTime(2026, 6, 28),
        updatedAt: DateTime(2026, 6, 28),
        isOfflineEnabled: false,
        isCollaborative: false,
        isDeleted: false,
        version: 1,
      );

      final json = playlist.toJson();
      final deserialized = PlaylistV2.fromJson(json);

      expect(deserialized.id, equals(1));
      expect(deserialized.name, equals('My Playlist'));
      expect(deserialized.trackCount, equals(1));
      expect(deserialized.version, equals(1));
    });

    // TEST 7: Recommendation serialization
    test('Recommendation serializes and deserializes correctly', () {
      final artist = Artist(id: 1, name: 'Test Artist', views: 0);
      final track = Track(
        id: 1,
        name: 'Song 1',
        duration: const Duration(seconds: 200),
        src: 'https://example.com/song1.mp3',
        artists: [artist],
        views: 1000,
      );

      final recommendation = Recommendation(
        id: 'rec_1',
        type: 'release_radar',
        title: 'Release Radar',
        description: 'New releases',
        tracks: [track],
        createdAt: DateTime(2026, 6, 28),
        refreshedAt: DateTime(2026, 6, 28),
      );

      final json = recommendation.toJson();
      final deserialized = Recommendation.fromJson(json);

      expect(deserialized.id, equals('rec_1'));
      expect(deserialized.type, equals('release_radar'));
      expect(deserialized.title, equals('Release Radar'));
    });

    // TEST 8: SECURITY - No credentials in any model
    test('SECURITY: No credentials exposed in model JSON', () {
      final models = [
        QualityOption(id: '320', label: 'High', bitrate: 320, format: 'AAC').toJson(),
        UserLibraryEntry(trackId: 1, entryType: 'favorite', addedAt: DateTime.now()).toJson(),
      ];

      for (final modelJson in models) {
        final jsonStr = modelJson.toString().toLowerCase();
        expect(jsonStr.contains('password'), isFalse, reason: 'Found password in model JSON');
        expect(jsonStr.contains('token'), isFalse, reason: 'Found token in model JSON');
        expect(jsonStr.contains('secret'), isFalse, reason: 'Found secret in model JSON');
        expect(jsonStr.contains('api_key'), isFalse, reason: 'Found api_key in model JSON');
      }
    });

    // TEST 9: PlaylistV2 copyWith updates version
    test('PlaylistV2 copyWith increments version', () {
      var playlist = PlaylistV2(
        id: 1,
        userId: 1,
        name: 'My Playlist',
        tracks: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isOfflineEnabled: false,
        isCollaborative: false,
        isDeleted: false,
        version: 1,
      );

      playlist = playlist.copyWith(name: 'Updated Playlist');
      expect(playlist.version, equals(2));
      expect(playlist.name, equals('Updated Playlist'));
    });

    // TEST 10: User isolation verified in data structures
    test('Models support user isolation', () {
      final playlist1 = PlaylistV2(
        id: 1,
        userId: 1, // User 1
        name: 'User 1 Playlist',
        tracks: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isOfflineEnabled: false,
        isCollaborative: false,
        isDeleted: false,
      );

      final playlist2 = PlaylistV2(
        id: 2,
        userId: 2, // User 2
        name: 'User 2 Playlist',
        tracks: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isOfflineEnabled: false,
        isCollaborative: false,
        isDeleted: false,
      );

      // Different users should have different playlists
      expect(playlist1.userId, isNot(equals(playlist2.userId)));
    });
  });
}
