# Track Menu System Integration Guide

This document explains how to integrate the new track action menu system into your ELSFM Flutter app, based on the BeMusic web player patterns.

## Overview

The track menu system provides a comprehensive set of actions for each track:
- **Share** - Share track via OS share sheet
- **Download** - Download track to device (permission-gated)
- **Add to Playlist** - Add track to a playlist
- **Add to Queue** - Add track to current playback queue
- **Like/Unlike** - Mark tracks as favorites
- **View Details** - Show detailed track information
- **Report Issue** - Report problematic tracks

## Components

### 1. **TrackAction Enum** (`track_action.dart`)
Defines all available track actions with localized labels and icons.

### 2. **TrackActionsService** (`track_actions_service.dart`)
Handles business logic for each action:
- Share via OS native share sheet
- Download with permission handling
- Playlist management
- Queue operations

### 3. **Riverpod Providers** (`track_actions_provider.dart`)
State management providers for:
- Track sharing
- Downloading
- Playlist operations
- Queue management

### 4. **UI Components**

#### **TrackContextMenu**
Drop-in menu content with track info and all actions.

#### **TrackMenuButton**
Button that shows menu as dialog when tapped. Usage:
```dart
TrackMenuButton(
  track: track,
  isLiked: isLiked,
  onShare: () => handleShare(),
  onDownload: () => handleDownload(),
  // ... other callbacks
)
```

#### **TrackMenuBottomSheet**
Mobile-optimized bottom sheet menu. Usage:
```dart
showTrackMenuBottomSheet(
  context,
  track,
  isLiked: true,
  onLikeTap: () => toggleLike(),
)
```

#### **TrackListItem**
Complete track list item with menu integration:
```dart
TrackListItem(
  track: track,
  index: 0,
  isPlaying: true,
  isLiked: isLiked,
  onTap: () => playTrack(),
  onLikeTap: () => toggleLike(),
  onShare: () => shareTrack(),
  // ... other callbacks
)
```

#### **PlayerTrackBar**
Compact track info bar for use in player screens with integrated menu.

## Integration Examples

### Example 1: Add Menu to Library/Songs Screen

```dart
// In your library songs screen
ListView.builder(
  itemCount: tracks.length,
  itemBuilder: (context, index) {
    final track = tracks[index];
    final isLiked = likedTracks.contains(track.id);
    
    return TrackListItem(
      track: track,
      index: index,
      isPlaying: currentTrack?.id == track.id,
      isLiked: isLiked,
      onTap: () => ref.read(playerProvider.notifier).playTrack(track),
      onLikeTap: () => toggleLike(track.id),
      onShare: () => shareTrack(track),
      onDownload: () => downloadTrack(track),
      onAddToPlaylist: () => showPlaylistSelector(track),
      onAddToQueue: () => ref.read(playerProvider.notifier).setQueue([...queue, track]),
      onViewDetails: () => showTrackDetails(track),
    );
  },
)
```

### Example 2: Add Menu to Player Screen

In your player screen, add the track bar:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final playerState = ref.watch(playerProvider);
  final currentTrack = playerState.currentTrack;

  return Column(
    children: [
      // Player artwork and controls
      // ...
      
      // Track info bar with menu
      PlayerTrackBar(
        currentTrack: currentTrack,
        onTrackTap: () => showTrackDetails(currentTrack),
      ),
      
      // Progress and playback controls
      // ...
    ],
  );
}
```

### Example 3: Custom Menu Positioning

Show menu as dialog at specific position:

```dart
GestureDetector(
  onLongPress: () {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: TrackContextMenu(
          track: track,
          isLiked: isLiked,
          onShare: () => handleShare(),
          // ... callbacks
        ),
      ),
    );
  },
  child: TrackTile(track),
)
```

### Example 4: Bottom Sheet Menu for Mobile

```dart
IconButton(
  icon: const Icon(Icons.more_vert),
  onPressed: () {
    showTrackMenuBottomSheet(
      context,
      track,
      isLiked: isLiked,
      onShare: () => shareTrack(track),
      onDownload: () => downloadTrack(track),
      // ... other callbacks
    );
  },
)
```

## Implementing Missing Actions

Some actions need additional implementation:

### Add to Playlist

Update `track_actions_service.dart`:

```dart
Future<void> addTrackToPlaylist(Track track, String playlistId) async {
  try {
    final response = await _httpClient.post(
      '/api/v1/playlists/$playlistId/tracks',
      data: {'track_id': track.id},
    );
    
    if (response.statusCode == 200) {
      debugPrint('Track added to playlist');
    }
  } catch (e) {
    debugPrint('Error: $e');
    rethrow;
  }
}
```

### Download Implementation

```dart
Future<bool> downloadTrack(Track track) async {
  try {
    final status = await Permission.storage.request();
    if (!status.isGranted) return false;

    final directory = await getApplicationDocumentsDirectory();
    final trackDir = Directory('${directory.path}/downloads/${track.id}');
    await trackDir.create(recursive: true);

    final file = File('${trackDir.path}/${track.title}.mp3');
    
    // Stream the audio
    final response = await _httpClient.get(
      '/api/v1/tracks/${track.id}/stream',
      options: Options(responseType: ResponseType.stream),
    );
    
    await response.data.stream.pipe(file.openWrite());
    return true;
  } catch (e) {
    debugPrint('Download error: $e');
    return false;
  }
}
```

### View Track Details

Create a track details sheet:

```dart
void showTrackDetails(Track track) {
  showModalBottomSheet(
    context: context,
    builder: (context) => TrackDetailsSheet(track: track),
  );
}
```

## Dependencies

Required packages (already added to pubspec.yaml):
- `share_plus: ^7.1.0` - Native share functionality
- `permission_handler: ^11.4.0` - Permission management

## Styling & Customization

All menu components respect your app's theme:

```dart
// Menu inherits from Theme.of(context)
// Customize by modifying theme colors:

ThemeData(
  primaryColor: Colors.blue,
  cardColor: Colors.white,
  textTheme: TextTheme(
    bodyMedium: TextStyle(color: Colors.black87),
    bodySmall: TextStyle(color: Colors.grey),
  ),
)
```

## Performance Considerations

- Menu items load lazily from Riverpod providers
- Share/download operations run async
- Playlist queries cached in state management
- Menu doesn't rebuild unnecessarily (const constructors)

## Best Practices

1. **Always provide callbacks** - All UI actions should be handled gracefully
2. **Show loading states** - Use SnackBars for feedback
3. **Handle errors** - Wrap in try-catch and show user-friendly messages
4. **Respect permissions** - Always request and check device permissions
5. **Test on both platforms** - iOS and Android have different menu behaviors

## Next Steps

1. Run `flutter pub get` to install dependencies
2. Add track menu to your library screen
3. Add track menu to player screen
4. Implement the remaining action callbacks
5. Test on Android and iOS devices
6. Add analytics tracking for menu interactions (optional)
