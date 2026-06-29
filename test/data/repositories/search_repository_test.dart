import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elsfm/data/repositories/search_repository.dart';
import 'package:elsfm/data/models/track.dart';
import 'package:elsfm/data/models/artist.dart';
import 'package:elsfm/data/models/album.dart';
import 'package:elsfm/data/models/playlist.dart';

// ---------------------------------------------------------------------------
// Minimal HttpClientAdapter stub.
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

// Build a Dio backed by the stub adapter.
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

ResponseBody _json(Map<String, dynamic> body, {int status = 200}) =>
    ResponseBody.fromString(
      _toJson(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

// Fixtures
Map<String, dynamic> _trackJson(int id) => {
      'id': id,
      'name': 'Track $id',
      'duration': 180000,
      'plays': '10',
      'artists': [
        {'id': 1, 'name': 'Artist', 'views': '0', 'plays': '0'}
      ],
    };

Map<String, dynamic> _artistJson(int id) =>
    {'id': id, 'name': 'Artist $id', 'views': '0', 'plays': '0'};

Map<String, dynamic> _albumJson(int id) =>
    {'id': id, 'name': 'Album $id', 'views': 0, 'artists': []};

Map<String, dynamic> _playlistJson(int id) => {
      'id': id,
      'name': 'Playlist $id',
      'public': true,
      'collaborative': false,
      'views': '0',
      'editors': [],
    };

void main() {
  group('SearchRepository.search', () {
    test('returns typed result maps for all sections', () async {
      final dio = _dioWith((_) async => _json({
            'results': {
              'tracks': {
                'data': [_trackJson(1), _trackJson(2)]
              },
              'artists': {
                'data': [_artistJson(10)]
              },
              'albums': {
                'data': [_albumJson(5)]
              },
              'playlists': {
                'data': [_playlistJson(99)]
              },
            }
          }));

      final repo = SearchRepository(dio: dio);
      final result = await repo.search(query: 'test');

      expect((result['songs'] as List<Track>).length, 2);
      expect((result['artists'] as List<Artist>).length, 1);
      expect((result['albums'] as List<Album>).length, 1);
      expect((result['playlists'] as List<Playlist>).length, 1);
    });

    test('sends q, type, and limit params', () async {
      RequestOptions? captured;
      final dio = _dioWith((opts) async {
        captured = opts;
        return _json({'results': {}});
      });

      final repo = SearchRepository(dio: dio);
      await repo.search(query: 'hello', perPage: 15);

      expect(captured?.queryParameters['q'], 'hello');
      expect(captured?.queryParameters['type'], 'track,artist,album,playlist');
      expect(captured?.queryParameters['limit'], 15);
    });

    test('handles empty results sections gracefully', () async {
      final dio = _dioWith((_) async => _json({'results': {}}));

      final repo = SearchRepository(dio: dio);
      final result = await repo.search(query: 'nothing');

      expect((result['songs'] as List).isEmpty, isTrue);
      expect((result['artists'] as List).isEmpty, isTrue);
    });

    test('rethrows DioException on network failure', () async {
      final dio = _dioWith((_) => Future.error(
            DioException(
              requestOptions: RequestOptions(path: '/search'),
              type: DioExceptionType.connectionError,
            ),
          ));

      final repo = SearchRepository(dio: dio);

      expect(
        () => repo.search(query: 'error'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('SearchRepository.searchSongs', () {
    test('parses tracks from pagination.data wrapper', () async {
      final dio = _dioWith((_) async => _json({
            'pagination': {
              'data': [_trackJson(1), _trackJson(2), _trackJson(3)],
            }
          }));

      final repo = SearchRepository(dio: dio);
      final tracks = await repo.searchSongs();

      expect(tracks.length, 3);
      expect(tracks.first.id, 1);
    });

    test('parses tracks from flat data key', () async {
      final dio = _dioWith((_) async => _json({
            'data': [_trackJson(10)],
          }));

      final repo = SearchRepository(dio: dio);
      final tracks = await repo.searchSongs();

      expect(tracks.length, 1);
      expect(tracks.first.id, 10);
    });

    test('sends artist_id when provided', () async {
      RequestOptions? captured;
      final dio = _dioWith((opts) async {
        captured = opts;
        return _json({'data': []});
      });

      final repo = SearchRepository(dio: dio);
      await repo.searchSongs(artistId: 42);

      expect(captured?.queryParameters['artist_id'], 42);
    });

    test('sends album_id when provided', () async {
      RequestOptions? captured;
      final dio = _dioWith((opts) async {
        captured = opts;
        return _json({'data': []});
      });

      final repo = SearchRepository(dio: dio);
      await repo.searchSongs(albumId: 7);

      expect(captured?.queryParameters['album_id'], 7);
    });

    test('does not include artist_id or album_id when not provided', () async {
      RequestOptions? captured;
      final dio = _dioWith((opts) async {
        captured = opts;
        return _json({'data': []});
      });

      final repo = SearchRepository(dio: dio);
      await repo.searchSongs();

      expect(captured?.queryParameters.containsKey('artist_id'), isFalse);
      expect(captured?.queryParameters.containsKey('album_id'), isFalse);
    });

    test('returns empty list when response is empty list', () async {
      final dio = _dioWith((_) async => _json({'data': []}));

      final repo = SearchRepository(dio: dio);
      final tracks = await repo.searchSongs();

      expect(tracks, isEmpty);
    });
  });

  group('SearchRepository.getTrending – songs', () {
    test('returns songs list keyed under "songs"', () async {
      final dio = _dioWith((_) async => _json({
            'pagination': {
              'data': [_trackJson(1)],
            }
          }));

      final repo = SearchRepository(dio: dio);
      final result = await repo.getTrending(type: 'songs');

      expect((result['songs'] as List<Track>).length, 1);
    });

    test('sends orderBy=plays, orderDir=desc', () async {
      RequestOptions? captured;
      final dio = _dioWith((opts) async {
        captured = opts;
        return _json({'pagination': {'data': []}});
      });

      final repo = SearchRepository(dio: dio);
      await repo.getTrending(type: 'songs');

      expect(captured?.queryParameters['orderBy'], 'plays');
      expect(captured?.queryParameters['orderDir'], 'desc');
    });
  });

  group('SearchRepository.getTrending – artists', () {
    test('returns artists list keyed under "artists"', () async {
      final dio = _dioWith((_) async => _json({
            'pagination': {
              'data': [_artistJson(5)],
            }
          }));

      final repo = SearchRepository(dio: dio);
      final result = await repo.getTrending(type: 'artists');

      expect((result['artists'] as List<Artist>).length, 1);
    });

    test('sends request to /artists endpoint', () async {
      RequestOptions? captured;
      final dio = _dioWith((opts) async {
        captured = opts;
        return _json({'pagination': {'data': []}});
      });

      final repo = SearchRepository(dio: dio);
      await repo.getTrending(type: 'artists');

      expect(captured?.path, contains('/artists'));
    });
  });
}
