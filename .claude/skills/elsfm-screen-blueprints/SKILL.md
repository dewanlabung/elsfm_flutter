---
name: elsfm-screen-blueprints
description: |
  Production-ready Flutter screen implementations for ELSFM. Complete blueprints for Player
  (full playback UI with controls, queue, lyrics), Library (tracks/albums/artists lists),
  Playlists (CRUD operations), Search (autocomplete, results), and Profile screens.
  Use when building new features, or as templates/starting points for screens.
---

# ELSFM Screen Blueprints

Complete, copy-paste-ready screen implementations.

## Quick Links

- **[player-screen.md](references/player-screen.md)** — Now Playing with full controls
- **[library-screen.md](references/library-screen.md)** — Tracks, Albums, Artists tabs
- **[playlist-screen.md](references/playlist-screen.md)** — Playlist view and CRUD
- **[search-screen.md](references/search-screen.md)** — Search UI with suggestions
- **[profile-screen.md](references/profile-screen.md)** — User profile and settings

## Implementation Patterns

All screens follow:
1. **Riverpod** for state
2. **AsyncValue.when()** for loading/error/data
3. **Responsive design** via LayoutBuilder
4. **Material 3** widgets
5. **Error handling** with retry

## Architecture

```
Screens (UI Layer)
├── lib/features/player/screens/now_playing_screen.dart
├── lib/features/library/screens/library_screen.dart
├── lib/features/playlist/screens/playlist_screen.dart
├── lib/features/search/screens/search_screen.dart
└── lib/features/profile/screens/profile_screen.dart

Widgets (Reusable Components)
├── lib/features/player/widgets/playback_controls.dart
├── lib/features/library/widgets/track_list_item.dart
└── lib/presentation/widgets/error_widget.dart

Providers (State)
├── lib/features/player/providers/player_notifier.dart
└── lib/data/providers/repository_providers.dart
```

## Copy-Paste Pattern

Each blueprint is self-contained:

```dart
// 1. Copy entire screen class
// 2. Adjust imports if needed (paths may vary)
// 3. Verify providers exist (apiClientProvider, etc.)
// 4. Run widget in GoRouter route

// Example: Add to app_router.dart
GoRoute(
  path: '/playlist/:id',
  pageBuilder: (context, state) => NoTransitionPage(
    child: PlaylistScreen(
      playlistId: int.parse(state.pathParameters['id']!),
    ),
  ),
),
```

## Common Dependencies

All screens assume these providers exist:

```dart
// Data
final trackRepositoryProvider     // TrackRepository
final playlistRepositoryProvider   // PlaylistRepository
final searchRepositoryProvider     // SearchRepository
final userRepositoryProvider       // UserRepository

// State
final playerProvider              // StateNotifierProvider<PlayerNotifier, PlayerState>
final authNotifierProvider        // StateNotifierProvider<AuthNotifier, AuthState>
final searchQueryProvider         // StateProvider<String>

// UI
final themeProvider               // Brightness (dark/light)
```

## Testing Screens

Use ProviderContainer to test:

```dart
testWidgets('displays tracks when loaded', (tester) async {
  final container = ProviderContainer(
    overrides: [
      trackRepositoryProvider.overrideWithValue(MockTrackRepository()),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: LibraryScreen()),
    ),
  );

  expect(find.byType(TrackListItem), findsWidgets);
});
```

## Reference Files

| File | Content |
|------|---------|
| [player-screen.md](references/player-screen.md) | NowPlayingScreen with full player UI |
| [library-screen.md](references/library-screen.md) | Tabbed library — Playlists, Songs, Artists, Albums |
| [playlist-screen.md](references/playlist-screen.md) | PlaylistScreen with FutureProvider.family and CRUD |
| [search-screen.md](references/search-screen.md) | SearchScreen with 400ms debounce and recent searches |
| [profile-screen.md](references/profile-screen.md) | ProfileScreen with auth guard and biometric toggle |

## Common Widgets Used

- **AppBar, Scaffold, Column, Row, ListView**
- **Card, ListTile, CircleAvatar**
- **FutureProvider.when(), AsyncValue**
- **TextField, Button, Icon**
- **RefreshIndicator, InfiniteList**

## Dark Theme Default

All screens use dark theme (Colors.grey[900], Colors.white text).

## Navigation

Standard routing via GoRouter:

```dart
// Navigate to track
context.go('/playlist/123');

// Pop back
context.pop();

// Push (keep history)
context.push('/now-playing');
```

## When to Use

- **Building new screen** → Copy most similar blueprint
- **Learning Riverpod UI patterns** → Study examples
- **Quick prototyping** → Start from blueprint, customize
- **Code review** → Compare to established pattern

## Customization

Blueprints are templates. Common changes:
- Adjust colors (theme.colorScheme)
- Change layout (add/remove columns)
- Add filters/sorting
- Modify error messages
- Adapt for different data

Start with blueprint, then customize for your needs.
