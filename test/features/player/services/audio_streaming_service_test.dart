import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:elsfm/features/player/services/audio_streaming_service.dart';

void main() {
  group('AudioStreamingService', () {
    late MockDio mockDio;
    late AudioStreamingService audioStreamingService;

    setUp(() {
      mockDio = MockDio();
      audioStreamingService = AudioStreamingService(dio: mockDio);
    });

    group('getStreamUrl', () {
      test('returns stream URL on success', () async {
        when(mockDio.get(
          '/api/v1/tracks/1/stream',
          queryParameters: {'quality': '320'},
        )).thenAnswer((_) async => Response(
          data: {'url': 'https://stream.elsfm.com/track1.mp3'},
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ));

        final url = await audioStreamingService.getStreamUrl(
          trackId: 1,
          quality: '320',
        );

        expect(url, equals('https://stream.elsfm.com/track1.mp3'));
      });

      test('throws AudioStreamException on missing URL', () async {
        when(mockDio.get(
          '/api/v1/tracks/1/stream',
          queryParameters: {'quality': '320'},
        )).thenAnswer((_) async => Response(
          data: {'error': 'Not found'},
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ));

        expect(
          () => audioStreamingService.getStreamUrl(
            trackId: 1,
            quality: '320',
          ),
          throwsA(isA<AudioStreamException>()),
        );
      });

      test('throws AudioStreamException on API error', () async {
        when(mockDio.get(
          '/api/v1/tracks/1/stream',
          queryParameters: {'quality': '320'},
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.unknown,
        ));

        expect(
          () => audioStreamingService.getStreamUrl(
            trackId: 1,
            quality: '320',
          ),
          throwsA(isA<AudioStreamException>()),
        );
      });
    });

    group('speed control', () {
      test('rejects speed outside valid range', () async {
        expect(
          () => audioStreamingService.setSpeed(3.0),
          throwsA(isA<AudioStreamException>()),
        );

        expect(
          () => audioStreamingService.setSpeed(0.1),
          throwsA(isA<AudioStreamException>()),
        );
      });
    });
  });
}

class MockDio extends Mock implements Dio {}
