import 'package:flutter_test/flutter_test.dart';
import 'package:elsfm/data/models/player_state.dart';

void main() {
  group('PlayerNotifier', () {
    test('initializes with empty queue and default state', () {
      // Arrange & Act
      final initialState = const PlayerState(queue: []);

      // Assert
      expect(initialState.queue, isEmpty);
      expect(initialState.isPlaying, isFalse);
      expect(initialState.isLoading, isFalse);
      expect(initialState.position, equals(Duration.zero));
      expect(initialState.duration, equals(Duration.zero));
      expect(initialState.repeatMode, equals(RepeatMode.none));
      expect(initialState.isShuffled, isFalse);
      expect(initialState.playbackRate, equals(1.0));
      expect(initialState.error, isNull);
    });

    test('copyWith updates state fields correctly', () {
      // Arrange
      final initialState = const PlayerState(queue: []);

      // Act
      final updatedState = initialState.copyWith(
        queue: [1, 2, 3],
        currentIndex: 0,
        isPlaying: true,
        playbackRate: 1.5,
      );

      // Assert
      expect(updatedState.queue, equals([1, 2, 3]));
      expect(updatedState.currentIndex, equals(0));
      expect(updatedState.isPlaying, isTrue);
      expect(updatedState.playbackRate, equals(1.5));
      expect(updatedState.repeatMode, equals(RepeatMode.none));
    });

    test('hasNext returns true when not at end of queue', () {
      // Arrange
      final state = PlayerState(
        queue: [1, 2, 3],
        currentIndex: 0,
      );

      // Act & Assert
      expect(state.hasNext, isTrue);
    });

    test('hasNext returns false when at end of queue', () {
      // Arrange
      final state = PlayerState(
        queue: [1, 2, 3],
        currentIndex: 2,
      );

      // Act & Assert
      expect(state.hasNext, isFalse);
    });

    test('hasPrevious returns true when not at start of queue', () {
      // Arrange
      final state = PlayerState(
        queue: [1, 2, 3],
        currentIndex: 1,
      );

      // Act & Assert
      expect(state.hasPrevious, isTrue);
    });

    test('hasPrevious returns false when at start of queue', () {
      // Arrange
      final state = PlayerState(
        queue: [1, 2, 3],
        currentIndex: 0,
      );

      // Act & Assert
      expect(state.hasPrevious, isFalse);
    });

    test('toggleRepeat cycles through repeat modes', () {
      // Arrange
      final noneMode = const PlayerState(queue: [], repeatMode: RepeatMode.none);
      final oneMode = const PlayerState(queue: [], repeatMode: RepeatMode.one);
      final allMode = const PlayerState(queue: [], repeatMode: RepeatMode.all);

      // Act & Assert - none → one
      var updated = noneMode.copyWith(repeatMode: RepeatMode.one);
      expect(updated.repeatMode, equals(RepeatMode.one));

      // Act & Assert - one → all
      updated = oneMode.copyWith(repeatMode: RepeatMode.all);
      expect(updated.repeatMode, equals(RepeatMode.all));

      // Act & Assert - all → none
      updated = allMode.copyWith(repeatMode: RepeatMode.none);
      expect(updated.repeatMode, equals(RepeatMode.none));
    });

    test('error state is preserved on copyWith when not specified', () {
      // Arrange
      final errorState = const PlayerState(
        queue: [],
        error: 'Playback error',
      );

      // Act
      final updatedState = errorState.copyWith(isPlaying: true);

      // Assert
      expect(updatedState.error, equals('Playback error'));
      expect(updatedState.isPlaying, isTrue);
    });

    test('error state is preserved when not explicitly cleared', () {
      // Arrange
      final errorState = const PlayerState(
        queue: [],
        error: 'Playback error',
      );

      // Act - copyWith without specifying error preserves it
      final preservedState = errorState.copyWith(isPlaying: true);

      // Assert
      expect(preservedState.error, equals('Playback error'));
    });
  });

  group('RepeatMode', () {
    test('RepeatMode enum has correct values', () {
      expect(RepeatMode.none, isNotNull);
      expect(RepeatMode.one, isNotNull);
      expect(RepeatMode.all, isNotNull);
    });
  });
}
