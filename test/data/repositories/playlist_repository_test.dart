import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:elsfm/data/repositories/playlist_repository.dart';
import 'package:elsfm/data/models/app_error.dart';

// ---------------------------------------------------------------------------
// Hive in-memory test helper.
// ---------------------------------------------------------------------------
Future<void> _initHive() async {
  final dir = await Directory.systemTemp.createTemp('hive_playlist_repo_test_');
  Hive.init(dir.path);
  if (!Hive.isBoxOpen('cache_playlists')) {
    await Hive.openBox<String>('cache_playlists');
  }
}

Future<void> _closeHive() async {
  await Hive.close();
}

// ---------------------------------------------------------------------------
// Stub adapter.
// ---------------------------------------------------------------------------
class _StubAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions) handler;
  _StubAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(RequestOptions options, _, __) =>
      handler(options);

  @override
  void close({bool force = false}) {}
}

Dio _dioWith(Future<ResponseBody> Function(RequestOptions) handler) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://www.elsfm.com/api/v1',
      validateStatus: (s) => s != null && s < 600,
    ),
  );
  dio.httpClientAdapter = _StubAdapter(handler);
  return dio;
}

String _toJson(dynamic v) {
  if (v == null) return 'null';
  if (v is bool) return v.toString();
  if (v is num) return v.toString();
  if (v is String) return '"${v.replaceAll('"', '\\"')}"';
  if (v is List) return '[${v.map(_toJson).join(',')}]';
  if (v is Map) {
    return '{${v.entries.map((e) => '"${e.key}":${_toJson(e.value)}').join(',')}}';
  }
  return '"$v"';
}

ResponseBody _json(dynamic body, {int status = 200}) =>
    ResponseBody.fromString(
      _toJson(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

// PlaylistV2 fixture — used for createPlaylist / getPlaylist / updatePlaylist responses.
Map<String, dynamic> _playlistV2Json({
  int id = 1,
  String name = 'Test Playlist',
}) {
  final now = DateTime(2026, 6, 29).toIso8601String();
  return {
    'id': id,
    'user_id': 7,
    'name': name,
    'description': null,
    'artwork': null,
    'tracks': [],
    'created_at': now,
    'updated_at': now,
    'is_offline_enabled': false,
    'is_collaborative': false,
    'is_deleted': false,
    'version': 1,
  };
}

// Playlist (simple model) fixture — used for addTracksToPlaylist / removeTracksFromPlaylist responses.
Map<String, dynamic> _playlistJson({
  int id = 1,
  String name = 'Test Playlist',
}) =>
    {
      'id': id,
      'name': name,
      'public': true,
      'collaborative': false,
      'views': '0',
      'editors': [],
    };

void main() {
  setUpAll(_initHive);
  tearDownAll(_closeHive);

  setUp(() async {
    await Hive.box<String>('cache_playlists').clear();
  });

  // -------------------------------------------------------------------------
  group('PlaylistRepository.createPlaylist', () {
    test('posts to /playlists and returns new PlaylistV2', () async {
      String? capturedPath;
      Map<String, dynamic>? capturedBody;

      final repo = PlaylistRepository(
        dio: _dioWith((opts) async {
          capturedPath = opts.path;
          capturedBody = opts.data as Map<String, dynamic>?;
          return _json(_playlistV2Json(id: 10, name: 'Road Trip'));
        }),
      );

      final playlist = await repo.createPlaylist(
        name: 'Road Trip',
        description: 'Best driving songs',
      );

      expect(capturedPath, endsWith('/playlists'));
      expect(capturedBody?['name'], 'Road Trip');
      expect(capturedBody?['description'], 'Best driving songs');
      expect(playlist.id, 10);
      expect(playlist.name, 'Road Trip');
    });

    test('unwraps playlist key from response body when present', () async {
      final repo = PlaylistRepository(
        dio: _dioWith((_) async => _json({
              'playlist': _playlistV2Json(id: 5, name: 'Wrapped'),
              'status': 'success',
            })),
      );

      final playlist = await repo.createPlaylist(name: 'Wrapped');

      expect(playlist.id, 5);
    });

    test('maps 401 to AuthError', () async {
      final repo = PlaylistRepository(
        dio: _dioWith((_) async {
          throw DioException(
            requestOptions: RequestOptions(path: '/playlists'),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: '/playlists'),
              statusCode: 401,
            ),
          );
        }),
      );

      expect(
        () => repo.createPlaylist(name: 'Fail'),
        throwsA(isA<AuthError>()),
      );
    });

    test('maps 422 to ValidationError', () async {
      final repo = PlaylistRepository(
        dio: _dioWith((_) async {
          throw DioException(
            requestOptions: RequestOptions(path: '/playlists'),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: '/playlists'),
              statusCode: 422,
              data: {'message': 'Name is required'},
            ),
          );
        }),
      );

      expect(
        () => repo.createPlaylist(name: ''),
        throwsA(isA<ValidationError>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  group('PlaylistRepository.getPlaylist', () {
    test('fetches playlist from network when cache empty', () async {
      final repo = PlaylistRepository(
        dio: _dioWith((_) async =>
            _json(_playlistV2Json(id: 5, name: 'Chill'))),
      );

      final playlist = await repo.getPlaylist(5);

      expect(playlist.id, 5);
      expect(playlist.name, 'Chill');
    });

    test('unwraps playlist key from response body', () async {
      final repo = PlaylistRepository(
        dio: _dioWith((_) async => _json({
              'playlist': _playlistV2Json(id: 8, name: 'Wrapped'),
              'status': 'success',
            })),
      );

      final playlist = await repo.getPlaylist(8);
      expect(playlist.id, 8);
    });

    test('returns cached playlist on second call without network hit', () async {
      int callCount = 0;
      final repo = PlaylistRepository(
        dio: _dioWith((_) async {
          callCount++;
          return _json(_playlistV2Json(id: 3));
        }),
      );

      await repo.getPlaylist(3);
      await repo.getPlaylist(3);

      expect(callCount, 1);
    });

    test('maps 404 to NotFoundError', () async {
      final repo = PlaylistRepository(
        dio: _dioWith((_) async {
          throw DioException(
            requestOptions: RequestOptions(path: '/playlists/999'),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: '/playlists/999'),
              statusCode: 404,
            ),
          );
        }),
      );

      expect(
        () => repo.getPlaylist(999),
        throwsA(isA<NotFoundError>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  group('PlaylistRepository.getUserPlaylists', () {
    test('returns list from network when cache empty', () async {
      final repo = PlaylistRepository(
        dio: _dioWith((_) async => _json([
              _playlistV2Json(id: 1, name: 'Workout'),
              _playlistV2Json(id: 2, name: 'Sleep'),
            ])),
      );

      final playlists = await repo.getUserPlaylists();

      expect(playlists.length, 2);
      expect(playlists.first.name, 'Workout');
    });

    test('returns cached list on second call without network hit', () async {
      int callCount = 0;
      final repo = PlaylistRepository(
        dio: _dioWith((_) async {
          callCount++;
          return _json([_playlistV2Json(id: 1)]);
        }),
      );

      await repo.getUserPlaylists();
      await repo.getUserPlaylists();

      expect(callCount, 1);
    });

    test('maps network error to NetworkError', () async {
      final repo = PlaylistRepository(
        dio: _dioWith((_) async {
          throw DioException(
            requestOptions: RequestOptions(path: '/playlists'),
            type: DioExceptionType.connectionTimeout,
          );
        }),
      );

      expect(
        () => repo.getUserPlaylists(),
        throwsA(isA<NetworkError>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  group('PlaylistRepository.updatePlaylist', () {
    test('sends PUT request with provided fields only', () async {
      String? capturedMethod;
      Map<String, dynamic>? capturedBody;

      final repo = PlaylistRepository(
        dio: _dioWith((opts) async {
          capturedMethod = opts.method;
          capturedBody = opts.data as Map<String, dynamic>?;
          return _json(_playlistV2Json(id: 1, name: 'Updated'));
        }),
      );

      final updated = await repo.updatePlaylist(
        playlistId: 1,
        name: 'Updated',
      );

      expect(capturedMethod, 'PUT');
      expect(capturedBody?['name'], 'Updated');
      // description was not passed — should not be in the body.
      expect(capturedBody?.containsKey('description'), isFalse);
      expect(updated.name, 'Updated');
    });

    test('sends all provided optional fields', () async {
      Map<String, dynamic>? capturedBody;
      final repo = PlaylistRepository(
        dio: _dioWith((opts) async {
          capturedBody = opts.data as Map<String, dynamic>?;
          return _json(_playlistV2Json(id: 2, name: 'Full Update'));
        }),
      );

      await repo.updatePlaylist(
        playlistId: 2,
        name: 'Full Update',
        description: 'New desc',
        isCollaborative: true,
        isPublic: false,
      );

      expect(capturedBody?['name'], 'Full Update');
      expect(capturedBody?['description'], 'New desc');
      expect(capturedBody?['collaborative'], true);
      expect(capturedBody?['public'], false);
    });

    test('maps 403 to ValidationError', () async {
      final repo = PlaylistRepository(
        dio: _dioWith((_) async {
          throw DioException(
            requestOptions: RequestOptions(path: '/playlists/1'),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: '/playlists/1'),
              statusCode: 403,
              data: {'message': 'Forbidden'},
            ),
          );
        }),
      );

      expect(
        () => repo.updatePlaylist(playlistId: 1, name: 'X'),
        throwsA(isA<ValidationError>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  group('PlaylistRepository.deletePlaylist', () {
    test('sends DELETE request to correct endpoint', () async {
      String? capturedPath;
      String? capturedMethod;

      final repo = PlaylistRepository(
        dio: _dioWith((opts) async {
          capturedPath = opts.path;
          capturedMethod = opts.method;
          return ResponseBody.fromString('', 204);
        }),
      );

      await repo.deletePlaylist(42);

      expect(capturedPath, endsWith('/playlists/42'));
      expect(capturedMethod, 'DELETE');
    });

    test('maps 404 to NotFoundError', () async {
      final repo = PlaylistRepository(
        dio: _dioWith((_) async {
          throw DioException(
            requestOptions: RequestOptions(path: '/playlists/999'),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: '/playlists/999'),
              statusCode: 404,
            ),
          );
        }),
      );

      expect(
        () => repo.deletePlaylist(999),
        throwsA(isA<NotFoundError>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  group('PlaylistRepository.addTracksToPlaylist', () {
    test('posts to /playlists/{id}/tracks/add with ids list', () async {
      String? capturedPath;
      Map<String, dynamic>? capturedBody;

      final repo = PlaylistRepository(
        dio: _dioWith((opts) async {
          capturedPath = opts.path;
          capturedBody = opts.data as Map<String, dynamic>?;
          return _json(_playlistJson(id: 1));
        }),
      );

      await repo.addTracksToPlaylist(playlistId: 1, trackIds: [7, 8, 9]);

      expect(capturedPath, endsWith('/playlists/1/tracks/add'));
      expect(capturedBody?['ids'], [7, 8, 9]);
    });

    test('maps 401 to AuthError', () async {
      final repo = PlaylistRepository(
        dio: _dioWith((_) async {
          throw DioException(
            requestOptions: RequestOptions(path: '/playlists/1/tracks/add'),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions:
                  RequestOptions(path: '/playlists/1/tracks/add'),
              statusCode: 401,
            ),
          );
        }),
      );

      expect(
        () => repo.addTracksToPlaylist(playlistId: 1, trackIds: [1]),
        throwsA(isA<AuthError>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  group('PlaylistRepository.removeTracksFromPlaylist', () {
    test('posts to /playlists/{id}/tracks/remove with ids list', () async {
      String? capturedPath;
      Map<String, dynamic>? capturedBody;

      final repo = PlaylistRepository(
        dio: _dioWith((opts) async {
          capturedPath = opts.path;
          capturedBody = opts.data as Map<String, dynamic>?;
          return _json(_playlistJson(id: 1));
        }),
      );

      await repo.removeTracksFromPlaylist(playlistId: 1, trackIds: [99]);

      expect(capturedPath, endsWith('/playlists/1/tracks/remove'));
      expect(capturedBody?['ids'], [99]);
    });
  });

  // -------------------------------------------------------------------------
  group('PlaylistRepository.addSongToPlaylist (legacy wrapper)', () {
    test('delegates to addTracksToPlaylist with single-element list', () async {
      Map<String, dynamic>? capturedBody;

      final repo = PlaylistRepository(
        dio: _dioWith((opts) async {
          capturedBody = opts.data as Map<String, dynamic>?;
          return _json(_playlistJson(id: 1));
        }),
      );

      await repo.addSongToPlaylist(playlistId: 1, trackId: 7);

      expect(capturedBody?['ids'], [7]);
    });
  });

  // -------------------------------------------------------------------------
  group('PlaylistRepository.removeSongFromPlaylist (legacy wrapper)', () {
    test('delegates to removeTracksFromPlaylist with single-element list',
        () async {
      Map<String, dynamic>? capturedBody;

      final repo = PlaylistRepository(
        dio: _dioWith((opts) async {
          capturedBody = opts.data as Map<String, dynamic>?;
          return _json(_playlistJson(id: 1));
        }),
      );

      await repo.removeSongFromPlaylist(playlistId: 1, trackId: 42);

      expect(capturedBody?['ids'], [42]);
    });
  });

  // -------------------------------------------------------------------------
  group('PlaylistRepository.getPlaylistTracks', () {
    test('returns paginated tracks from /playlists/{id}/tracks', () async {
      final trackJson = {
        'id': 1,
        'name': 'Track 1',
        'duration': 200000,
        'plays': '10',
        'artists': [
          {'id': 1, 'name': 'Artist', 'views': '0', 'plays': '0'}
        ],
      };

      final repo = PlaylistRepository(
        dio: _dioWith((_) async => _json({
              'pagination': {
                'data': [trackJson],
                'current_page': 1,
                'last_page': 1,
                'total': 1,
                'per_page': 20,
              }
            })),
      );

      final result = await repo.getPlaylistTracks(1);

      expect(result.data.length, 1);
      expect(result.data.first.name, 'Track 1');
    });

    test('maps 404 to NotFoundError', () async {
      final repo = PlaylistRepository(
        dio: _dioWith((_) async {
          throw DioException(
            requestOptions: RequestOptions(path: '/playlists/999/tracks'),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions:
                  RequestOptions(path: '/playlists/999/tracks'),
              statusCode: 404,
            ),
          );
        }),
      );

      expect(
        () => repo.getPlaylistTracks(999),
        throwsA(isA<NotFoundError>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  group('PlaylistRepository.followPlaylist / unfollowPlaylist', () {
    test('followPlaylist posts to /playlists/{id}/follow', () async {
      String? capturedPath;

      final repo = PlaylistRepository(
        dio: _dioWith((opts) async {
          capturedPath = opts.path;
          return ResponseBody.fromString('', 200);
        }),
      );

      await repo.followPlaylist(10);

      expect(capturedPath, endsWith('/playlists/10/follow'));
    });

    test('unfollowPlaylist posts to /playlists/{id}/unfollow', () async {
      String? capturedPath;

      final repo = PlaylistRepository(
        dio: _dioWith((opts) async {
          capturedPath = opts.path;
          return ResponseBody.fromString('', 200);
        }),
      );

      await repo.unfollowPlaylist(10);

      expect(capturedPath, endsWith('/playlists/10/unfollow'));
    });

    test('followPlaylist maps 401 to AuthError', () async {
      final repo = PlaylistRepository(
        dio: _dioWith((_) async {
          throw DioException(
            requestOptions: RequestOptions(path: '/playlists/1/follow'),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: '/playlists/1/follow'),
              statusCode: 401,
            ),
          );
        }),
      );

      expect(
        () => repo.followPlaylist(1),
        throwsA(isA<AuthError>()),
      );
    });
  });
}
