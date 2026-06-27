import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:elsfm/features/player/services/player_service.dart';
import 'package:elsfm/features/player/services/audio_streaming_service.dart';
import 'package:elsfm/data/models/track.dart';
import 'package:elsfm/data/models/artist.dart';

void main() {
  group('PlayerService Integration', () {
    late MockAudioStreamingService mockAudioStreamingService;
    late PlayerService playerService;
    late Track testTrack;

    setUp(() {
      mockAudioStreamingService = MockAudioStreamingService();
      playerService = PlayerService(audioStreamingService: mockAudioStreamingService);

      testTrack = Track(
        id: 1,
        name: 'Test Song',
        artists: [Artist(id: 1, name: 'Test Artist', views: 0)],
        album: 'Test Album',
        duration: Duration(minutes: 3),
        createdAt: DateTime.now(),
        genre: 'Test',
      );
    });

    group('loadTrack', () {
      test('loads track and auto-plays', () async {
        when(mockAudioStreamingService.loadTrack(
          track: testTrack,
          quality: '320',
        )).thenAnswer((_) async {});

        when(mockAudioStreamingService.play()).thenAnswer((_) async {});

        await playerService.loadTrack(testTrack);

        expect(playerService.currentTrack, equals(testTrack));
        expect(playerService.isPlaying, isTrue);
        expect(playerService.position, equals(Duration.zero));

        verify(mockAudioStreamingService.loadTrack(
          track: testTrack,
          quality: '320',
        )).called(1);

        verify(mockAudioStreamingService.play()).called(1);
      });

      test('loads track without auto-play', () async {
        when(mockAudioStreamingService.loadTrack(
          track: testTrack,
          quality: '320',
        )).thenAnswer((_) async {});

        await playerService.loadTrack(testTrack, autoPlay: false);

        expect(playerService.currentTrack, equals(testTrack));
        expect(playerService.isPlaying, isFalse);

        verifyNever(mockAudioStreamingService.play());
      });
    });

    group('playback control', () {
      test('play delegates to audio streaming service', () async {
        when(mockAudioStreamingService.play()).thenAnswer((_) async {});

        await playerService.play();

        expect(playerService.isPlaying, isTrue);
        verify(mockAudioStreamingService.play()).called(1);
      });

      test('pause delegates to audio streaming service', () async {
        when(mockAudioStreamingService.pause()).thenAnswer((_) async {});

        await playerService.pause();

        expect(playerService.isPlaying, isFalse);
        verify(mockAudioStreamingService.pause()).called(1);
      });

      test('seek delegates to audio streaming service', () async {
        final seekPosition = Duration(seconds: 30);
        when(mockAudioStreamingService.seek(seekPosition)).thenAnswer((_) async {});

        await playerService.seek(seekPosition);

        expect(playerService.position, equals(seekPosition));
        verify(mockAudioStreamingService.seek(seekPosition)).called(1);
      });
    });

    group('quality control', () {
      test('sets preferred quality', () async {
        playerService.setPreferredQuality('lossless');

        when(mockAudioStreamingService.loadTrack(
          track: testTrack,
          quality: 'lossless',
        )).thenAnswer((_) async {});

        await playerService.loadTrack(testTrack, autoPlay: false);

        verify(mockAudioStreamingService.loadTrack(
          track: testTrack,
          quality: 'lossless',
        )).called(1);
      });
    });
  });
}

class MockAudioStreamingService extends Mock implements AudioStreamingService {}
