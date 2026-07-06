import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents the player overlay state for fullscreen/mini-player UI.
/// Inspired by web's player-overlay-store.ts from ELSFM web.
class PlayerOverlayState {
  const PlayerOverlayState({
    this.isFullscreen = false,
    this.isQueueOpen = false,
  });

  final bool isFullscreen;
  final bool isQueueOpen;

  PlayerOverlayState copyWith({
    bool? isFullscreen,
    bool? isQueueOpen,
  }) {
    return PlayerOverlayState(
      isFullscreen: isFullscreen ?? this.isFullscreen,
      isQueueOpen: isQueueOpen ?? this.isQueueOpen,
    );
  }
}

/// Notifier for managing player overlay state (fullscreen, queue visibility).
/// Equivalent to Zustand store in web with toggle/toggleQueue methods.
class PlayerOverlayNotifier extends StateNotifier<PlayerOverlayState> {
  PlayerOverlayNotifier() : super(const PlayerOverlayState());

  /// Toggle fullscreen on/off. Closes queue when entering fullscreen.
  void toggle() {
    state = state.copyWith(
      isFullscreen: !state.isFullscreen,
      isQueueOpen: false, // Close queue when toggling fullscreen
    );
  }

  /// Toggle queue panel visibility. Only relevant in fullscreen mode.
  void toggleQueue() {
    if (state.isFullscreen) {
      state = state.copyWith(isQueueOpen: !state.isQueueOpen);
    }
  }

  /// Open fullscreen player.
  void open() {
    state = state.copyWith(isFullscreen: true, isQueueOpen: false);
  }

  /// Close fullscreen player (return to mini-player).
  void close() {
    state = state.copyWith(isFullscreen: false, isQueueOpen: false);
  }

  /// Set queue visibility (useful when route changes).
  void closeQueue() {
    state = state.copyWith(isQueueOpen: false);
  }

  /// Set fullscreen visibility (useful for back button handling).
  void setFullscreen(bool fullscreen) {
    state = state.copyWith(
      isFullscreen: fullscreen,
      isQueueOpen: false, // Reset queue when fullscreen changes
    );
  }
}

/// Riverpod provider for player overlay state.
/// Usage: ref.watch(playerOverlayStateProvider)
final playerOverlayStateProvider =
    StateNotifierProvider<PlayerOverlayNotifier, PlayerOverlayState>(
  (ref) => PlayerOverlayNotifier(),
);
