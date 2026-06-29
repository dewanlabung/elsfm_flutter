import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:elsfm/data/repositories/track_repository.dart';
import 'package:elsfm/data/models/app_error.dart';

// ---------------------------------------------------------------------------
// Hive in-memory test helper.
// ---------------------------------------------------------------------------
Future<void> _initHive() async {
  final dir = await Directory.systemTemp.createTemp('hive_track_repo_test_');
  Hive.init(dir.path);
  if (!Hive.isBoxOpen('cache_tracks')) {
    await Hive.openBox<String>('cache_tracks');
  }
}

Future<void> _closeHive() async {
  await Hive.close();
}

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

ResponseBody _errorResponse(int status) => ResponseBody.fromString(
      '{"message":"Error $status"}',
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

// Track fixture
Map<String, dynamic> _trackJson({int id = 1, String name = 'Test Track'}) => {
      'id': id,
      'name': name,
      'duration': 240000,
      'plays': '100',
      'artists': [
        {'id': 1, 'name': 'Artist', 'views': '0', 'plays': '0'}
      ],
    };

// Pagination wrapper
Map<String, dynamic> _paginatedTracks(List<Map<String, dynamic>> tracks) => {
      'pagination': {
        'data': tracks,
        'current_page': 1,
        'last_page': 2,
        'total': tracks.length + 20,
        'per_page': 20,
      }
    };

void main() {
  setUpAll(_initHive);
  tearDownAll(_closeHive);

  setUp(() async {
    // Clear the tracks box between tests.
    await Hive.box<String>('cache_tracks').clear();
  });

  // -------------------------------------------------------------------------
  group('TrackRepository.getTrack', () {
    test('fetches track from network when cache is empty', () async {
      final repo = TrackRepository(
        dio: _dioWith((_) async => _json(_trackJson(id: 42))),
      );

      final track = await repo.getTrack(42);

      expect(track.id, 42);
      expect(track.name, 'Test Track');
    });

    test('returns cached track on second call without network hit', () async {
      int callCount = 0;
      final repo = TrackRepository(
        dio: _dioWith((_) async {
          callCount++;
          return _json(_trackJson(id: 7));
        }),
      );

      await repo.getTrack(7); // First call — network.
      await repo.getTrack(7); // Second call — should be from cache.

      expect(callCount, 1);
    });

    test('maps 404 DioException to NotFoundError', () async {
      final repo = TrackRepository(
        dio: _dioWith((_) async {
          throw DioException(
            requestOptions: RequestOptions(path: '/tracks/999'),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: '/tracks/999'),
              statusCode: 404,
            ),
          );
        }),
      );

      expect(
        () => repo.getTrack(999),
        throwsA(isA<NotFoundError>()),
      );
    });

    test('maps 401 to AuthError', () async {
      final repo = TrackRepository(
        dio: _dioWith((_) async {
          throw DioException(
            requestOptions: RequestOptions(path: '/tracks/1'),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: '/tracks/1'),
              statusCode: 401,
            ),
          );
        }),
      );

      expect(
        () => repo.getTrack(1),
        throwsA(isA<AuthError>()),
      );
    });

    test('maps connection timeout to NetworkError', () async {
      final repo = TrackRepository(
        dio: _dioWith((_) async {
          throw DioException(
            requestOptions: RequestOptions(path: '/tracks/1'),
            type: DioExceptionType.connectionTimeout,
          );
        }),
      );

      expect(
        () => repo.getTrack(1),
        throwsA(isA<NetworkError>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  group('TrackRepository.getTracks', () {
    test('returns paginated tracks from network', () async {
      final repo = TrackRepository(
        dio: _dioWith((_) async => _json(
              _paginatedTracks([_trackJson(id: 1), _trackJson(id: 2)]),
            )),
      );

      final result = await repo.getTracks();

      expect(result.data.length, 2);
      expect(result.currentPage, 1);
      expect(result.lastPage, 2);
    });

    test('caches page 1 result and serves it on second call', () async {
      int callCount = 0;
      final repo = TrackRepository(
        dio: _dioWith((_) async {
          callCount++;
          return _json(
            _paginatedTracks([_trackJson(id: 10)]),
          );
        }),
      );

      await repo.getTracks(page: 1);
      await repo.getTracks(page: 1);

      expect(callCount, 1);
    });

    test('does not cache page 2 results', () async {
      int callCount = 0;
      final repo = TrackRepository(
        dio: _dioWith((_) async {
          callCount++;
          return _json(
            _paginatedTracks([_trackJson(id: 20)]),
          );
        }),
      );

      // Page 2 — should always hit network.
      await repo.getTracks(page: 2);
      await repo.getTracks(page: 2);

      expect(callCount, 2);
    });

    test('falls back to flat response when no pagination key', () async {
      final repo = TrackRepository(
        dio: _dioWith((_) async => _json({
              'data': [_trackJson(id: 5)],
              'current_page': 1,
              'last_page': 1,
              'total': 1,
              'per_page': 20,
            })),
      );

      final result = await repo.getTracks();

      expect(result.data.length, 1);
      expect(result.data.first.id, 5);
    });

    test('maps 500 to UnknownError', () async {
      final repo = TrackRepository(
        dio: _dioWith((_) async {
          throw DioException(
            requestOptions: RequestOptions(path: '/tracks'),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: '/tracks'),
              statusCode: 500,
            ),
          );
        }),
      );

      expect(
        () => repo.getTracks(),
        throwsA(isA<UnknownError>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  group('TrackRepository.invalidateTrack', () {
    test('removes cached entry so next read hits network', () async {
      int callCount = 0;
      final repo = TrackRepository(
        dio: _dioWith((_) async {
          callCount++;
          return _json(_trackJson(id: 3));
        }),
      );

      await repo.getTrack(3);   // Populates cache.
      await repo.invalidateTrack(3); // Clears cache.
      await repo.getTrack(3);   // Should hit network again.

      expect(callCount, 2);
    });
  });
}
