import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elsfm/data/services/api_client.dart';

// ---------------------------------------------------------------------------
// Minimal HttpClientAdapter stub that returns a pre-built ResponseBody.
// This lets us inject arbitrary JSON responses without a real HTTP server.
// ---------------------------------------------------------------------------
class _StubAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions) handler;

  _StubAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      handler(options);

  @override
  void close({bool force = false}) {}
}

/// Build a [Dio] + [ApiClient] where every request is answered by [handler].
ApiClient _clientWith(
    Future<ResponseBody> Function(RequestOptions) handler) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://www.elsfm.com/api/v1',
      validateStatus: (s) => s != null && s < 600,
    ),
  );
  dio.httpClientAdapter = _StubAdapter(handler);
  return ApiClient(dio);
}

/// Encode a Map as a UTF-8 stream and wrap it in a [ResponseBody].
ResponseBody _jsonResponse(
  Map<String, dynamic> body, {
  int status = 200,
}) {
  final bytes = List<int>.from(
    '{"_stub":true}'.codeUnits, // placeholder; Dio deserialises from raw bytes
  );
  // Provide raw JSON bytes correctly:
  final jsonStr = _mapToJsonString(body);
  return ResponseBody.fromString(
    jsonStr,
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
}

String _mapToJsonString(dynamic value) {
  if (value == null) return 'null';
  if (value is bool) return value.toString();
  if (value is num) return value.toString();
  if (value is String) return '"${value.replaceAll('"', '\\"')}"';
  if (value is List) {
    return '[${value.map(_mapToJsonString).join(',')}]';
  }
  if (value is Map) {
    final pairs = value.entries
        .map((e) => '"${e.key}":${_mapToJsonString(e.value)}')
        .join(',');
    return '{$pairs}';
  }
  return '"$value"';
}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------
Map<String, dynamic> _artistJson({int id = 1, String name = 'Test Artist'}) => {
      'id': id,
      'name': name,
      'views': '100',
      'plays': '200',
    };

Map<String, dynamic> _trackJson({int id = 1, String name = 'Test Track'}) => {
      'id': id,
      'name': name,
      'duration': 200000,
      'plays': '50',
      'artists': [_artistJson()],
    };

Map<String, dynamic> _albumJson({int id = 1, String name = 'Test Album'}) => {
      'id': id,
      'name': name,
      'views': 300,
      'artists': [_artistJson()],
    };

Map<String, dynamic> _paginationWrapper(List<Map<String, dynamic>> items) => {
      'data': items,
      'current_page': 1,
      'last_page': 3,
      'total': 60,
      'per_page': 20,
    };

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  group('ApiClient – getArtists', () {
    test('returns a PaginationResponse with artist list', () async {
      final client = _clientWith((_) async => _jsonResponse(
            _paginationWrapper([_artistJson(id: 1), _artistJson(id: 2)]),
          ));

      final result = await client.getArtists();

      expect(result.data.length, 2);
      expect(result.currentPage, 1);
      expect(result.lastPage, 3);
      expect(result.total, 60);
    });

    test('sends page and per_page as query params', () async {
      RequestOptions? captured;
      final client = _clientWith((opts) async {
        captured = opts;
        return _jsonResponse(_paginationWrapper([]));
      });

      await client.getArtists(page: 2, perPage: 10);

      expect(captured?.queryParameters['page'], 2);
      expect(captured?.queryParameters['per_page'], 10);
    });
  });

  group('ApiClient – getArtistTracks', () {
    test('returns a PaginationResponse of tracks for a given artist', () async {
      final client = _clientWith((_) async => _jsonResponse(
            _paginationWrapper([_trackJson(id: 10), _trackJson(id: 11)]),
          ));

      final result = await client.getArtistTracks(99);

      expect(result.data.length, 2);
      expect(result.data.first.id, 10);
    });
  });

  group('ApiClient – getArtistAlbums', () {
    test('returns a PaginationResponse of albums for a given artist', () async {
      final client = _clientWith((_) async => _jsonResponse(
            _paginationWrapper([_albumJson(id: 5)]),
          ));

      final result = await client.getArtistAlbums(99);

      expect(result.data.length, 1);
      expect(result.data.first.id, 5);
    });
  });

  group('ApiClient – getAlbums', () {
    test('returns a PaginationResponse with album list', () async {
      final client = _clientWith((_) async => _jsonResponse(
            _paginationWrapper([_albumJson()]),
          ));

      final result = await client.getAlbums();

      expect(result.data.length, 1);
    });
  });

  group('ApiClient – getTracks', () {
    test('unwraps pagination key when present', () async {
      final client = _clientWith((_) async => _jsonResponse({
            'pagination': _paginationWrapper([_trackJson(id: 7)]),
            'status': 'success',
          }));

      final result = await client.getTracks();

      expect(result.data.length, 1);
      expect(result.data.first.id, 7);
    });

    test('falls back to flat data key when no pagination wrapper', () async {
      final client = _clientWith((_) async => _jsonResponse(
            _paginationWrapper([_trackJson(id: 8)]),
          ));

      final result = await client.getTracks();

      expect(result.data.length, 1);
      expect(result.data.first.id, 8);
    });

    test('sends orderBy / orderDir / perPage query params', () async {
      RequestOptions? captured;
      final client = _clientWith((opts) async {
        captured = opts;
        return _jsonResponse(_paginationWrapper([]));
      });

      await client.getTracks(
          page: 1, perPage: 50, orderBy: 'created_at', orderDir: 'asc');

      expect(captured?.queryParameters['orderBy'], 'created_at');
      expect(captured?.queryParameters['orderDir'], 'asc');
      expect(captured?.queryParameters['perPage'], 50);
    });
  });

  group('ApiClient – getPlaylists', () {
    test('unwraps pagination key when present', () async {
      final playlistJson = {
        'id': 1,
        'name': 'Chill',
        'public': true,
        'collaborative': false,
        'views': '10',
        'editors': [],
      };

      final client = _clientWith((_) async => _jsonResponse({
            'pagination': {
              'data': [playlistJson],
              'current_page': 1,
              'last_page': 1,
              'total': 1,
              'per_page': 20,
            }
          }));

      final result = await client.getPlaylists();

      expect(result.data.length, 1);
      expect(result.data.first.name, 'Chill');
    });
  });

  group('ApiClient – search', () {
    test('returns raw response map with results key', () async {
      final client = _clientWith((_) async => _jsonResponse({
            'results': {
              'tracks': {'data': []},
              'artists': {'data': []},
            }
          }));

      final result = await client.search(query: 'adele');

      expect(result.containsKey('results'), isTrue);
    });

    test('sends q, type, and limit query params', () async {
      RequestOptions? captured;
      final client = _clientWith((opts) async {
        captured = opts;
        return _jsonResponse({'results': {}});
      });

      await client.search(
          query: 'hello', type: 'track,artist', limit: 10);

      expect(captured?.queryParameters['q'], 'hello');
      expect(captured?.queryParameters['type'], 'track,artist');
      expect(captured?.queryParameters['limit'], 10);
    });
  });

  group('ApiClient – getCurrentUser', () {
    test('parses user from user wrapper', () async {
      final client = _clientWith((_) async => _jsonResponse({
            'user': {
              'id': 42,
              'name': 'Jane',
              'email': 'jane@test.com',
            }
          }));

      final user = await client.getCurrentUser();

      expect(user.id, 42);
      expect(user.name, 'Jane');
    });

    test('parses user from flat response when user key absent', () async {
      final client = _clientWith((_) async => _jsonResponse({
            'id': 5,
            'name': 'John',
            'email': 'john@test.com',
          }));

      final user = await client.getCurrentUser();

      expect(user.id, 5);
    });
  });

  group('ApiClient – getGenres', () {
    test('parses genres from pagination wrapper', () async {
      final genreJson = {'id': 1, 'name': 'pop'};
      final client = _clientWith((_) async => _jsonResponse({
            'pagination': {
              'data': [genreJson],
            }
          }));

      final genres = await client.getGenres();

      expect(genres.length, 1);
      expect(genres.first.name, 'pop');
    });

    test('parses genres from flat data key', () async {
      final genreJson = {'id': 2, 'name': 'rock'};
      final client = _clientWith((_) async => _jsonResponse({
            'data': [genreJson],
          }));

      final genres = await client.getGenres();

      expect(genres.length, 1);
      expect(genres.first.id, 2);
    });

    test('returns empty list when neither key present', () async {
      final client = _clientWith((_) async => _jsonResponse({'status': 'ok'}));

      final genres = await client.getGenres();

      expect(genres, isEmpty);
    });
  });

  group('ApiClient – logTrackPlay', () {
    test('posts to the correct endpoint and does not throw', () async {
      String? capturedPath;
      final client = _clientWith((opts) async {
        capturedPath = opts.path;
        return ResponseBody.fromString('', 200);
      });

      await expectLater(client.logTrackPlay(42), completes);
      expect(capturedPath, endsWith('/tracks/plays/42/log'));
    });

    test('swallows errors silently', () async {
      final client = _clientWith((_) => Future.error(
            DioException(
              requestOptions: RequestOptions(path: '/tracks/plays/1/log'),
              type: DioExceptionType.connectionError,
            ),
          ));

      // Should not throw.
      await expectLater(client.logTrackPlay(1), completes);
    });
  });

  group('ApiClient – getTrackLyrics', () {
    test('returns data map on success', () async {
      final client = _clientWith((_) async => _jsonResponse({
            'lyrics': {'text': 'Hello, it\'s me'}
          }));

      final result = await client.getTrackLyrics(500);

      expect(result, isNotNull);
      expect(result!.containsKey('lyrics'), isTrue);
    });

    test('returns null on error', () async {
      final client = _clientWith((_) => Future.error(
            DioException(
              requestOptions: RequestOptions(path: '/tracks/1/lyrics'),
              type: DioExceptionType.badResponse,
              response: Response(
                requestOptions: RequestOptions(path: '/tracks/1/lyrics'),
                statusCode: 404,
              ),
            ),
          ));

      final result = await client.getTrackLyrics(1);
      expect(result, isNull);
    });
  });

  group('ApiClient – getArtistBio', () {
    test('extracts bio.content field', () async {
      final client = _clientWith((_) async => _jsonResponse({
            'bio': {'content': 'Born in London…'}
          }));

      final bio = await client.getArtistBio(1);
      expect(bio, 'Born in London…');
    });

    test('returns null when bio absent', () async {
      final client = _clientWith((_) async => _jsonResponse({}));
      final bio = await client.getArtistBio(1);
      expect(bio, isNull);
    });

    test('returns null on network error', () async {
      final client = _clientWith((_) => Future.error(
            DioException(
              requestOptions: RequestOptions(path: '/artists/1/bio'),
              type: DioExceptionType.connectionError,
            ),
          ));

      final bio = await client.getArtistBio(1);
      expect(bio, isNull);
    });
  });

  group('ApiClient – getLikedTracks', () {
    test('returns paginated track list', () async {
      final client = _clientWith((_) async => _jsonResponse(
            _paginationWrapper([_trackJson(id: 20)]),
          ));

      final result = await client.getLikedTracks(7);

      expect(result.data.length, 1);
      expect(result.data.first.id, 20);
    });
  });

  group('ApiClient – getLikedAlbums', () {
    test('returns paginated album list', () async {
      final client = _clientWith((_) async => _jsonResponse(
            _paginationWrapper([_albumJson(id: 30)]),
          ));

      final result = await client.getLikedAlbums(7);

      expect(result.data.length, 1);
      expect(result.data.first.id, 30);
    });
  });

  group('ApiClient – getUserPlaylists', () {
    test('returns paginated playlist list', () async {
      final playlistJson = {
        'id': 99,
        'name': 'My Playlist',
        'public': false,
        'collaborative': false,
        'views': '5',
        'editors': [],
      };
      final client = _clientWith((_) async => _jsonResponse(
            _paginationWrapper([playlistJson]),
          ));

      final result = await client.getUserPlaylists(7);

      expect(result.data.length, 1);
      expect(result.data.first.name, 'My Playlist');
    });
  });

  group('ApiClient – _parsePaginationResponse', () {
    test('uses defaults when pagination fields absent', () async {
      final client = _clientWith((_) async => _jsonResponse({'data': []}));

      final result = await client.getArtists();

      expect(result.currentPage, 1);
      expect(result.lastPage, 1);
      expect(result.total, 0);
    });
  });
}
