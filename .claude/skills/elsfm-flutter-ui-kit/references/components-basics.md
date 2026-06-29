# Basic Components

Essential Material 3 components for ELSFM UI.

## Buttons

### FilledButton (Primary Action)
Default Material 3 button for primary actions (play, save, submit).

```dart
FilledButton(
  onPressed: () => playerNotifier.play(),
  child: const Text('Play'),
)

// With icon
FilledButton.icon(
  onPressed: onPressed,
  icon: const Icon(Icons.play_arrow),
  label: const Text('Play'),
)

// Disabled state
FilledButton(
  onPressed: null,  // null disables button
  child: const Text('Play'),
)
```

### OutlinedButton (Secondary Action)
Use for secondary actions that still need to be visible.

```dart
OutlinedButton(
  onPressed: () => showPlaylistDialog(),
  child: const Text('Add to Playlist'),
)

OutlinedButton.icon(
  onPressed: onPressed,
  icon: const Icon(Icons.add),
  label: const Text('Add'),
)
```

### TextButton (Tertiary Action)
Minimal button for actions that don't demand attention.

```dart
TextButton(
  onPressed: () => Navigator.pop(context),
  child: const Text('Cancel'),
)

// In dialogs
TextButton(onPressed: onPressed, child: const Text('OK'))
```

### IconButton
Buttons with only icons, useful for AppBar and toolbars.

```dart
IconButton(
  onPressed: () => playerNotifier.togglePlayPause(),
  icon: const Icon(Icons.play_arrow),
  tooltip: 'Play',  // Accessibility label
)

// Filled variant (uses primary color)
IconButton.filled(
  onPressed: onPressed,
  icon: const Icon(Icons.favorite),
)

// Filledtonal (muted primary color)
IconButton.filledTonal(
  onPressed: onPressed,
  icon: const Icon(Icons.share),
)
```

## Text Fields

### TextFormField (Recommended)
Use within a Form for validation.

```dart
TextFormField(
  decoration: InputDecoration(
    labelText: 'Playlist Name',
    hintText: 'Enter playlist name',
    prefixIcon: const Icon(Icons.music_note),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a name';
    }
    return null;
  },
  onSaved: (value) => _playlistName = value,
)
```

### TextField (Stateless)
For simple input without validation.

```dart
TextField(
  decoration: InputDecoration(
    labelText: 'Search',
    prefixIcon: const Icon(Icons.search),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  onChanged: (value) => setState(() => _query = value),
)
```

## Cards

### Basic Card
Container for related content.

```dart
Card(
  elevation: 3,
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Text('Album Name', style: theme.textTheme.headlineSmall),
        Text('Artist Name', style: theme.textTheme.bodyMedium),
      ],
    ),
  ),
)
```

### Track Card
Represents a single track with album art, title, artist.

```dart
Card(
  child: ListTile(
    leading: Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        image: DecorationImage(
          image: NetworkImage(track.image ?? ''),
          fit: BoxFit.cover,
        ),
      ),
    ),
    title: Text(track.name),
    subtitle: Text(track.artists.map((a) => a.name).join(', ')),
    trailing: IconButton(
      icon: const Icon(Icons.more_vert),
      onPressed: () => _showTrackMenu(context, track),
    ),
    onTap: () => playerNotifier.playTrack(track),
  ),
)
```

### Album/Playlist Card
Grid-friendly card for album covers with title below.

```dart
Card(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(album.image ?? ''),
            fit: BoxFit.cover,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              album.name,
              style: theme.textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              album.artists.first.name,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ],
  ),
)
```

## Chips

### Filter Chip
Used in search/filter interfaces.

```dart
FilterChip(
  label: const Text('Rock'),
  onSelected: (isSelected) {
    setState(() => _selectedGenres.toggle('rock'));
  },
  selected: _selectedGenres.contains('rock'),
)
```

### Input Chip
Represents user input that can be removed.

```dart
InputChip(
  label: const Text('Favorite Tracks'),
  onDeleted: () => setState(() => _tags.remove('Favorite Tracks')),
  deleteIcon: const Icon(Icons.close),
)
```

## Lists

### ListTile
Standard list item with leading, title, subtitle, trailing.

```dart
ListTile(
  leading: CircleAvatar(
    backgroundImage: NetworkImage(artist.image ?? ''),
  ),
  title: Text(artist.name),
  subtitle: Text('${artist.albumCount} albums'),
  trailing: const Icon(Icons.arrow_forward),
  onTap: () => context.go('/artist/${artist.id}'),
)
```

### Custom List Item
For more complex layouts.

```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  child: Row(
    children: [
      // Leading image
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          image: DecorationImage(
            image: NetworkImage(track.image ?? ''),
            fit: BoxFit.cover,
          ),
        ),
      ),
      const SizedBox(width: 12),
      // Title + subtitle
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(track.name, style: theme.textTheme.titleMedium),
            Text(track.artists.map((a) => a.name).join(', '),
                style: theme.textTheme.bodySmall),
          ],
        ),
      ),
      // Trailing button
      IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () => showTrackMenu(context, track),
      ),
    ],
  ),
)
```

## Progress Indicators

### LinearProgressIndicator (Progress Bar)
For finite progress (download, file upload).

```dart
LinearProgressIndicator(
  value: 0.7,  // 0.0 to 1.0
  minHeight: 4,
  backgroundColor: Colors.grey[800],
  valueColor: AlwaysStoppedAnimation<Color>(Colors.green[400]!),
)

// Indeterminate (loading)
const LinearProgressIndicator()
```

### CircularProgressIndicator (Spinner)
For indefinite loading.

```dart
const CircularProgressIndicator()

// With value (progress ring)
CircularProgressIndicator(
  value: 0.7,
)

// Centered in screen
const Scaffold(
  body: Center(child: CircularProgressIndicator()),
)
```

## Dividers

### Divider
Horizontal line separator.

```dart
const Divider(height: 16, thickness: 1)

// Custom colors
Divider(
  color: Colors.grey[800],
  height: 24,
)
```

### VerticalDivider
Vertical separator for side-by-side layouts.

```dart
const VerticalDivider(width: 16, thickness: 1)
```

## Empty States

### No Data Message

```dart
Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.music_note, size: 64, color: Colors.grey[600]),
      const SizedBox(height: 16),
      Text(
        'No tracks yet',
        style: theme.textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      Text(
        'Add tracks to get started',
        style: theme.textTheme.bodyMedium,
      ),
    ],
  ),
)
```

## Error States

### Error Message

```dart
Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        Icons.error_outline,
        size: 64,
        color: theme.colorScheme.error,
      ),
      const SizedBox(height: 16),
      Text(
        'Something went wrong',
        style: theme.textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      Text(error.message, style: theme.textTheme.bodyMedium),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: () => ref.refresh(myProvider),
        child: const Text('Retry'),
      ),
    ],
  ),
)
```

## Touch Targets

All interactive elements must be at least 48x48 dp (44x44 dp minimum).

```dart
// ✅ Good: 48x48 minimum
IconButton(
  onPressed: onPressed,
  icon: const Icon(Icons.favorite),
  // Implicit 48x48 size
)

// ⚠️ Borderline: Small icon in a larger container
Container(
  width: 48,
  height: 48,
  alignment: Alignment.center,
  child: const Icon(Icons.play_arrow, size: 24),
)

// ✅ Good: Use hitTestSize if needed
GestureDetector(
  onTap: onTap,
  behavior: HitTestBehavior.opaque,  // Makes entire area tappable
  child: const Icon(Icons.share),
)
```
