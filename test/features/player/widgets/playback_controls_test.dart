import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elsfm/features/player/widgets/playback_controls.dart';
import 'package:elsfm/data/models/track.dart';
import 'package:elsfm/data/models/artist.dart';

void main() {
  group('PlaybackControls', () {
    late Track testTrack;

    setUp(() {
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

    testWidgets('renders all control buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope(
              child: PlaybackControls(),
            ),
          ),
        ),
      );

      // Check for shuffle button
      expect(find.byIcon(Icons.shuffle), findsOneWidget);

      // Check for skip previous button
      expect(find.byIcon(Icons.skip_previous), findsOneWidget);

      // Check for play button
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Check for skip next button
      expect(find.byIcon(Icons.skip_next), findsOneWidget);

      // Check for repeat button
      expect(find.byIcon(Icons.repeat), findsOneWidget);
    });
  });
}
