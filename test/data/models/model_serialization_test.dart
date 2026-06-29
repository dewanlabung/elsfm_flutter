import 'package:flutter_test/flutter_test.dart';
import 'package:elsfm/data/models/track.dart';
import 'package:elsfm/data/models/album.dart';
import 'package:elsfm/data/models/artist.dart';
import 'package:elsfm/data/models/playlist.dart';
import 'package:elsfm/data/models/playlist_v2.dart';
import 'package:elsfm/data/models/user.dart';
import 'package:elsfm/data/models/genre.dart';
import 'package:elsfm/data/models/tag.dart';
import 'package:elsfm/data/models/backend_response.dart';
import 'package:elsfm/data/models/image_helper.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Artist
  // ---------------------------------------------------------------------------
  group('Artist.fromJson / toJson', () {
    test('parses all fields from full detail response', () {
      final json = {
        'id': 42,
        'name': 'Adele',
        'image': 'storage/artist_images/adele.jpg',
        'views': '711',
        'plays': '1712',
      };

      final artist = Artist.fromJson(json);

      expect(artist.id, 42);
      expect(artist.name, 'Adele');
      expect(artist.image, 'https://www.elsfm.com/storage/artist_images/adele.jpg');
      expect(artist.views, 711);
      expect(artist.plays, 1712);
    });

    test('falls back to image_small for embedded contexts', () {
      final json = {
        'id': 1,
        'name': 'Test',
        'image_small': 'storage/artist_images/small.jpg',
        'views': '0',
        'plays': '0',
      };

      final artist = Artist.fromJson(json);
      expect(artist.image, 'https://www.elsfm.com/storage/artist_images/small.jpg');
    });

    test('handles missing optional fields with safe defaults', () {
      final json = {'id': 1, 'name': 'Unknown'};

      final artist = Artist.fromJson(json);
      expect(artist.views, 0);
      expect(artist.plays, 0);
      expect(artist.image, '');
    });

    test('round-trips through toJson → fromJson', () {
      final original = Artist(
        id: 10,
        name: 'Coldplay',
        image: 'https://www.elsfm.com/storage/artist_images/coldplay.jpg',
        views: 5000,
        plays: 12000,
      );

      final json = original.toJson();
      // toJson uses 'image' key; fromJson picks 'image' in the absence of
      // 'image_small', so we need to add it back for a proper round-trip.
      final restored = Artist.fromJson({'image': json['image'], ...json});

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.views, original.views);
      expect(restored.plays, original.plays);
    });

    test('parses integer views/plays even when API sends strings', () {
      final json = {'id': 5, 'name': 'Dua Lipa', 'views': '999', 'plays': '2048'};
      final artist = Artist.fromJson(json);
      expect(artist.views, 999);
      expect(artist.plays, 2048);
    });

    test('handles absolute image URL without prepending base', () {
      final json = {
        'id': 7,
        'name': 'Ed Sheeran',
        'image': 'https://cdn.example.com/ed.jpg',
        'views': '0',
        'plays': '0',
      };
      final artist = Artist.fromJson(json);
      expect(artist.image, 'https://cdn.example.com/ed.jpg');
    });
  });

  // ---------------------------------------------------------------------------
  // Album
  // ---------------------------------------------------------------------------
  group('Album.fromJson / toJson', () {
    test('parses all fields', () {
      final json = {
        'id': 101,
        'name': '25',
        'image': 'storage/album_images/25.jpg',
        'release_date': '2015-11-20T00:00:00Z',
        'views': 4500,
        'artists': [
          {'id': 42, 'name': 'Adele', 'views': '711', 'plays': '1712'},
        ],
      };

      final album = Album.fromJson(json);

      expect(album.id, 101);
      expect(album.name, '25');
      expect(album.releaseYear, 2015);
      expect(album.views, 4500);
      expect(album.artists.length, 1);
      expect(album.artists.first.name, 'Adele');
    });

    test('falls back to release_year integer when release_date is absent', () {
      final json = {
        'id': 200,
        'name': 'Album',
        'release_year': 2020,
        'views': 0,
        'artists': [],
      };

      final album = Album.fromJson(json);
      expect(album.releaseYear, 2020);
    });

    test('handles null image gracefully', () {
      final json = {'id': 1, 'name': 'No Image Album', 'views': 0, 'artists': []};
      final album = Album.fromJson(json);
      expect(album.image, '');
    });

    test('round-trips through toJson → fromJson', () {
      final original = Album(
        id: 5,
        name: 'Test Album',
        image: 'https://www.elsfm.com/storage/album_images/test.jpg',
        releaseYear: 2022,
        artists: [],
        views: 100,
      );

      final json = original.toJson();
      // toJson writes release_year; fromJson also reads release_year as fallback.
      final restored = Album.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.releaseYear, original.releaseYear);
      expect(restored.views, original.views);
    });
  });

  // ---------------------------------------------------------------------------
  // Track
  // ---------------------------------------------------------------------------
  group('Track.fromJson / toJson', () {
    test('parses all fields from API response', () {
      final json = {
        'id': 500,
        'name': 'Hello',
        'image': 'storage/track_image_media/hello.png',
        'duration': 295000,
        'artists': [
          {'id': 42, 'name': 'Adele', 'views': '711', 'plays': '1712'},
        ],
        'album': {
          'id': 101,
          'name': '25',
          'views': 4500,
          'artists': [],
        },
        'plays': '75',
        'created_at': '2015-10-23T00:00:00.000Z',
      };

      final track = Track.fromJson(json);

      expect(track.id, 500);
      expect(track.name, 'Hello');
      expect(track.image, 'https://www.elsfm.com/storage/track_image_media/hello.png');
      expect(track.duration.inMilliseconds, 295000);
      expect(track.plays, 75);
      expect(track.artists.length, 1);
      expect(track.album?.name, '25');
      expect(track.createdAt?.year, 2015);
    });

    test('parses plays as string (API quirk)', () {
      final json = {
        'id': 1,
        'name': 'Track',
        'duration': 0,
        'plays': '999',
        'artists': [],
      };
      final track = Track.fromJson(json);
      expect(track.plays, 999);
    });

    test('uses empty src when stream url absent', () {
      final json = {'id': 1, 'name': 'Track', 'duration': 0, 'plays': '0', 'artists': []};
      final track = Track.fromJson(json);
      expect(track.src, '');
    });

    test('picks up src from url field if src absent', () {
      final json = {
        'id': 1,
        'name': 'Track',
        'url': 'https://cdn.example.com/track.mp3',
        'duration': 0,
        'plays': '0',
        'artists': [],
      };
      final track = Track.fromJson(json);
      expect(track.src, 'https://cdn.example.com/track.mp3');
    });

    test('round-trips through toJson → fromJson', () {
      final artist = Artist(id: 1, name: 'Artist', views: 0, plays: 0);
      final original = Track(
        id: 10,
        name: 'My Track',
        duration: const Duration(seconds: 210),
        src: '',
        artists: [artist],
        plays: 55,
      );

      final json = original.toJson();
      final restored = Track.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.duration.inSeconds, original.duration.inSeconds);
      expect(restored.plays, original.plays);
    });

    test('handles null album', () {
      final json = {'id': 1, 'name': 'Track', 'duration': 0, 'plays': '0', 'artists': []};
      final track = Track.fromJson(json);
      expect(track.album, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Playlist (simple model)
  // ---------------------------------------------------------------------------
  group('Playlist.fromJson / toJson', () {
    test('parses all fields', () {
      final json = {
        'id': 20,
        'name': 'Chill Vibes',
        'public': true,
        'collaborative': false,
        'image': 'storage/playlist_media/chill.png',
        'views': '220',
        'owner_id': 7,
        'editors': [
          {'id': 7, 'name': 'Owner'},
        ],
      };

      final playlist = Playlist.fromJson(json);

      expect(playlist.id, 20);
      expect(playlist.name, 'Chill Vibes');
      expect(playlist.isPublic, isTrue);
      expect(playlist.collaborative, isFalse);
      expect(playlist.views, 220);
      expect(playlist.ownerId, 7);
      expect(playlist.editors.length, 1);
    });

    test('parses views from string (API quirk)', () {
      final json = {
        'id': 1,
        'name': 'Test',
        'public': false,
        'collaborative': false,
        'views': '99',
        'editors': [],
      };
      final playlist = Playlist.fromJson(json);
      expect(playlist.views, 99);
    });

    test('round-trips through toJson → fromJson', () {
      final original = Playlist(
        id: 5,
        name: 'Workout',
        isPublic: true,
        collaborative: false,
        views: 100,
        editors: [],
      );

      final json = original.toJson();
      final restored = Playlist.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.isPublic, original.isPublic);
      expect(restored.views, original.views);
    });
  });

  // ---------------------------------------------------------------------------
  // User
  // ---------------------------------------------------------------------------
  group('User.fromJson / toJson', () {
    test('parses all fields', () {
      final json = {
        'id': 99,
        'name': 'Jane Doe',
        'email': 'jane@example.com',
        'avatar': 'storage/avatars/jane.jpg',
        'email_verified_at': '2026-01-01T00:00:00Z',
      };

      final user = User.fromJson(json);

      expect(user.id, 99);
      expect(user.name, 'Jane Doe');
      expect(user.email, 'jane@example.com');
      expect(user.emailVerified, isTrue);
      expect(user.avatar, 'https://www.elsfm.com/storage/avatars/jane.jpg');
    });

    test('email_verified is false when field is null', () {
      final json = {'id': 1, 'name': 'John', 'email': 'john@example.com'};
      final user = User.fromJson(json);
      expect(user.emailVerified, isFalse);
    });

    test('round-trips through toJson → fromJson', () {
      final original = User(
        id: 3,
        name: 'Test User',
        email: 'test@test.com',
        emailVerified: false,
      );

      final json = original.toJson();
      final restored = User.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.email, original.email);
      expect(restored.name, original.name);
    });

    test('resolves absolute avatar URL without modification', () {
      final json = {
        'id': 2,
        'name': 'User',
        'email': 'u@u.com',
        'avatar': 'https://elsfm.com/storage/avatars/u.jpg',
      };
      final user = User.fromJson(json);
      expect(user.avatar, 'https://elsfm.com/storage/avatars/u.jpg');
    });
  });

  // ---------------------------------------------------------------------------
  // Genre
  // ---------------------------------------------------------------------------
  group('Genre.fromJson / toJson', () {
    test('parses all fields', () {
      final json = {
        'id': 1,
        'name': 'pop',
        'display_name': 'Pop',
        'image': 'storage/genre_images/pop.jpg',
      };

      final genre = Genre.fromJson(json);

      expect(genre.id, 1);
      expect(genre.name, 'pop');
      expect(genre.displayName, 'Pop');
      expect(genre.label, 'Pop');
      expect(genre.image, 'https://www.elsfm.com/storage/genre_images/pop.jpg');
    });

    test('label falls back to name when displayName is null', () {
      final json = {'id': 2, 'name': 'rock'};
      final genre = Genre.fromJson(json);
      expect(genre.label, 'rock');
    });

    test('round-trips through toJson → fromJson', () {
      final original = Genre(id: 5, name: 'jazz', displayName: 'Jazz');
      final json = original.toJson();
      final restored = Genre.fromJson(json);

      expect(restored.id, 5);
      expect(restored.name, 'jazz');
      expect(restored.displayName, 'Jazz');
    });
  });

  // ---------------------------------------------------------------------------
  // Tag
  // ---------------------------------------------------------------------------
  group('Tag.fromJson / toJson', () {
    test('parses id and name', () {
      final json = {'id': 10, 'name': 'acoustic'};
      final tag = Tag.fromJson(json);
      expect(tag.id, 10);
      expect(tag.name, 'acoustic');
    });

    test('round-trips through toJson → fromJson', () {
      final original = Tag(id: 3, name: 'instrumental');
      final json = original.toJson();
      final restored = Tag.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.name, original.name);
    });
  });

  // ---------------------------------------------------------------------------
  // BackendResponse / PaginationResponse
  // ---------------------------------------------------------------------------
  group('BackendResponse', () {
    test('parses success envelope', () {
      final json = {
        'status': 'success',
        'success': true,
        'message': 'OK',
        'data': {'id': 1},
      };

      final response = BackendResponse.fromJson(
        json,
        (d) => d as Map<String, dynamic>,
      );

      expect(response.success, isTrue);
      expect(response.message, 'OK');
      expect(response.data['id'], 1);
    });

    test('defaults success to true when field absent', () {
      final json = {'data': 'payload'};
      final response = BackendResponse.fromJson(json, (d) => d as String);
      expect(response.success, isTrue);
    });
  });

  group('PaginationResponse', () {
    test('parses paginated list', () {
      final json = {
        'data': [
          {'id': 1},
          {'id': 2},
        ],
        'total': 100,
        'per_page': 20,
        'current_page': 1,
        'last_page': 5,
      };

      final response = PaginationResponse.fromJson(
        json,
        (d) => d as Map<String, dynamic>,
      );

      expect(response.data.length, 2);
      expect(response.total, 100);
      expect(response.perPage, 20);
      expect(response.currentPage, 1);
      expect(response.lastPage, 5);
      expect(response.hasMore, isTrue);
    });

    test('hasMore is false on last page', () {
      final json = {
        'data': [],
        'total': 10,
        'per_page': 10,
        'current_page': 1,
        'last_page': 1,
      };

      final response = PaginationResponse.fromJson(json, (d) => d);
      expect(response.hasMore, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // resolveImageUrl helper
  // ---------------------------------------------------------------------------
  group('resolveImageUrl', () {
    test('prepends base URL to relative path', () {
      expect(
        resolveImageUrl('storage/track_image_media/foo.png'),
        'https://www.elsfm.com/storage/track_image_media/foo.png',
      );
    });

    test('leaves https URL untouched', () {
      const url = 'https://elsfm.com/storage/avatars/user.jpg';
      expect(resolveImageUrl(url), url);
    });

    test('leaves http URL untouched', () {
      const url = 'http://cdn.example.com/img.jpg';
      expect(resolveImageUrl(url), url);
    });

    test('returns empty string for null input', () {
      expect(resolveImageUrl(null), '');
    });

    test('returns empty string for empty string input', () {
      expect(resolveImageUrl(''), '');
    });
  });

  // ---------------------------------------------------------------------------
  // PlaylistV2 model operations
  // ---------------------------------------------------------------------------
  group('PlaylistV2', () {
    Artist _artist() => Artist(id: 1, name: 'Artist', views: 0, plays: 0);

    Track _track(int id, String name) => Track(
          id: id,
          name: name,
          duration: const Duration(seconds: 200),
          src: '',
          artists: [Artist(id: 1, name: 'Artist', views: 0, plays: 0)],
          plays: 0,
        );

    test('fromJson parses all fields', () {
      final now = DateTime(2026, 6, 29);
      final json = {
        'id': 1,
        'user_id': 7,
        'name': 'Road Trip',
        'description': 'Best songs for the road',
        'artwork': null,
        'tracks': [],
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'is_offline_enabled': false,
        'is_collaborative': false,
        'is_deleted': false,
        'version': 3,
      };

      final playlist = PlaylistV2.fromJson(json);

      expect(playlist.id, 1);
      expect(playlist.userId, 7);
      expect(playlist.name, 'Road Trip');
      expect(playlist.description, 'Best songs for the road');
      expect(playlist.version, 3);
      expect(playlist.isDeleted, isFalse);
    });

    test('addTrack appends track and increments version', () {
      final t1 = _track(1, 'Song 1');
      final t2 = _track(2, 'Song 2');

      var playlist = PlaylistV2(
        id: 1,
        userId: 1,
        name: 'Test',
        tracks: [t1],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isOfflineEnabled: false,
        isCollaborative: false,
        isDeleted: false,
        version: 1,
      );

      playlist = playlist.addTrack(t2);

      expect(playlist.trackCount, 2);
      expect(playlist.version, 2);
    });

    test('addTrack prevents duplicates', () {
      final t1 = _track(1, 'Song 1');

      var playlist = PlaylistV2(
        id: 1,
        userId: 1,
        name: 'Test',
        tracks: [t1],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isOfflineEnabled: false,
        isCollaborative: false,
        isDeleted: false,
        version: 1,
      );

      playlist = playlist.addTrack(t1);
      expect(playlist.trackCount, 1);
    });

    test('removeTrack removes by id', () {
      final t1 = _track(1, 'Song 1');
      final t2 = _track(2, 'Song 2');

      var playlist = PlaylistV2(
        id: 1,
        userId: 1,
        name: 'Test',
        tracks: [t1, t2],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isOfflineEnabled: false,
        isCollaborative: false,
        isDeleted: false,
      );

      playlist = playlist.removeTrack(1);

      expect(playlist.trackCount, 1);
      expect(playlist.tracks.first.id, 2);
    });

    test('reorderTrack moves track to new index', () {
      final t1 = _track(1, 'A');
      final t2 = _track(2, 'B');
      final t3 = _track(3, 'C');

      var playlist = PlaylistV2(
        id: 1,
        userId: 1,
        name: 'Test',
        tracks: [t1, t2, t3],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isOfflineEnabled: false,
        isCollaborative: false,
        isDeleted: false,
      );

      // Move first track to last position.
      playlist = playlist.reorderTrack(0, 2);

      expect(playlist.tracks[0].id, 2);
      expect(playlist.tracks[1].id, 3);
      expect(playlist.tracks[2].id, 1);
    });

    test('round-trips through toJson → fromJson', () {
      final now = DateTime(2026, 1, 1);
      final artist = _artist();
      final track = _track(99, 'Round Trip Song');

      final original = PlaylistV2(
        id: 10,
        userId: 5,
        name: 'Serializable',
        description: 'A description',
        tracks: [track],
        createdAt: now,
        updatedAt: now,
        isOfflineEnabled: true,
        isCollaborative: false,
        isDeleted: false,
        version: 7,
      );

      final json = original.toJson();
      final restored = PlaylistV2.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.userId, original.userId);
      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.trackCount, 1);
      expect(restored.isOfflineEnabled, isTrue);
      expect(restored.version, 7);
    });

    test('equality is based on id and userId only', () {
      final p1 = PlaylistV2(
        id: 1,
        userId: 2,
        name: 'Playlist A',
        tracks: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isOfflineEnabled: false,
        isCollaborative: false,
        isDeleted: false,
      );
      final p2 = PlaylistV2(
        id: 1,
        userId: 2,
        name: 'Playlist B',
        tracks: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isOfflineEnabled: true,
        isCollaborative: true,
        isDeleted: false,
      );

      expect(p1 == p2, isTrue);
    });
  });
}
