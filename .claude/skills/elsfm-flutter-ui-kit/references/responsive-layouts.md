# Responsive Layouts

Adaptive designs for multiple screen sizes (320px to 1440px+).

## Breakpoints

```dart
class Breakpoints {
  // Phone devices (320-479px)
  static const phone = 320.0;
  static const phoneMax = 479.0;

  // Phablet (480-599px)
  static const phablet = 480.0;
  static const phabletMax = 599.0;

  // Tablet (600-1023px)
  static const tablet = 600.0;
  static const tabletMax = 1023.0;

  // Desktop (1024-1439px)
  static const desktop = 1024.0;
  static const desktopMax = 1439.0;

  // Large desktop (1440px+)
  static const largeDesktop = 1440.0;

  // Helper methods
  static bool isPhone(BuildContext context) =>
      MediaQuery.of(context).size.width < 480;

  static bool isPhablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 480 &&
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1024;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1440;
}
```

## Pattern 1: LayoutBuilder (Recommended)

Responsive layout based on available width.

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final isWide = constraints.maxWidth >= 600;

    if (isWide) {
      // Tablet/Desktop: 2 or 3 columns
      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1,
        children: albumCards,
      );
    } else {
      // Phone: 1 column (vertical list)
      return ListView(
        children: trackTiles,
      );
    }
  },
)
```

## Pattern 2: MediaQuery.of(context).size

Direct size checking (less elegant but clear).

```dart
final screenWidth = MediaQuery.of(context).size.width;
final isWide = screenWidth >= 600;

return isWide
    ? Row(children: [leftPanel, rightPanel])
    : Column(children: [topPanel, bottomPanel]);
```

## Pattern 3: Orientation-Based

Respond to device orientation changes.

```dart
OrientationBuilder(
  builder: (context, orientation) {
    final isPortrait = orientation == Orientation.portrait;

    return GridView.count(
      crossAxisCount: isPortrait ? 2 : 4,
      children: items,
    );
  },
)
```

## Example Layouts

### Phone (320-479px)

**Track List Screen (Single Column)**
```
┌────────────────┐
│ Your Library   │
├────────────────┤
│ [Image] Track  │ ← 100% width, stack vertically
│         Artist │
├────────────────┤
│ [Image] Track  │
│         Artist │
├────────────────┤
│    ...more...  │
└────────────────┘
```

```dart
ListView.builder(
  itemCount: tracks.length,
  itemBuilder: (context, index) {
    return ListTile(
      leading: TrackArtwork(imageUrl: tracks[index].image),
      title: Text(tracks[index].name),
      subtitle: Text(tracks[index].artists.first.name),
    );
  },
)
```

### Tablet (600-1023px)

**Album Grid (2-3 columns)**
```
┌────────────────────────┐
│ Albums                 │
├─────────────┬──────────┤
│ [Album 1]   │ [Album2] │ ← 2 columns
│ Name        │ Name     │
├─────────────┼──────────┤
│ [Album 3]   │ [Album4] │
│ Name        │ Name     │
└─────────────┴──────────┘
```

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final columns = constraints.maxWidth < 800 ? 2 : 3;

    return GridView.count(
      crossAxisCount: columns,
      childAspectRatio: 0.8,
      children: albumCards,
    );
  },
)
```

### Desktop (1024px+)

**Sidebar Navigation + Content**
```
┌──────┬────────────────────┐
│Navi- │ Album              │
│ gat  │ List               │
│ ion  │                    │
│──────┼────────────────────┤
│      │ ┌──────┬──────┬──┐ │
│ Home │ │Album │Album │..│ │
│ Sear-│ │ 1    │ 2    │  │ │
│ ch   │ ├──────┼──────┼──┤ │
│ Lib. │ │Album │Album │..│ │
│      │ │ 3    │ 4    │  │ │
│      │ └──────┴──────┴──┘ │
└──────┴────────────────────┘
```

```dart
Row(
  children: [
    // Sidebar (250px)
    SizedBox(
      width: 250,
      child: Drawer(child: navigationItems),
    ),
    // Content (flexible)
    Expanded(
      child: GridView.count(
        crossAxisCount: 4,
        children: albumCards,
      ),
    ),
  ],
)
```

## Responsive AppBar

```dart
AppBar(
  title: MediaQuery.of(context).size.width < 600
      ? const Text('ELSFM')  // Short on phone
      : const Text('ELSFM Music Streaming'),  // Full on tablet+
  centerTitle: MediaQuery.of(context).size.width < 600,  // Centered on phone
  actions: MediaQuery.of(context).size.width < 600
      ? [
          // Phone: Icon buttons only
          IconButton(icon: Icon(Icons.search), onPressed: onSearch),
          IconButton(icon: Icon(Icons.more_vert), onPressed: onMenu),
        ]
      : [
          // Tablet+: Text buttons
          TextButton.icon(
            icon: Icon(Icons.search),
            label: Text('Search'),
            onPressed: onSearch,
          ),
          TextButton.icon(
            icon: Icon(Icons.more_vert),
            label: Text('More'),
            onPressed: onMenu,
          ),
        ],
)
```

## Dialog vs BottomSheet

```dart
final isMobile = MediaQuery.of(context).size.width < 600;

if (isMobile) {
  // Phone: Use BottomSheet
  showModalBottomSheet(context: context, builder: (_) => bottomSheetContent);
} else {
  // Tablet+: Use Dialog
  showDialog(context: context, builder: (_) => dialogContent);
}
```

## Responsive Padding

```dart
// Adapt padding to screen size
final horizontalPadding = MediaQuery.of(context).size.width > 600
    ? 32.0  // Desktop: larger padding
    : 16.0; // Phone: tighter padding

Padding(
  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
  child: child,
)

// Or use a helper
double responsivePadding(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width > 1024) return 48.0;
  if (width > 600) return 32.0;
  return 16.0;
}
```

## Image Sizing

Images should be sized responsively.

```dart
LayoutBuilder(
  builder: (context, constraints) {
    // Phone: 80% of screen width, max 300px
    // Desktop: 300px fixed
    final imageWidth = constraints.maxWidth > 600
        ? 300.0
        : constraints.maxWidth * 0.8;

    return Image.network(
      imageUrl,
      width: imageWidth,
      height: imageWidth,
      fit: BoxFit.cover,
    );
  },
)
```

## Safe Areas

Account for notches, rounded corners, system UI:

```dart
SafeArea(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: child,
  ),
)
```

## Testing Responsive Design

### Use Device Previews

In pubspec.yaml:
```yaml
dev_dependencies:
  device_preview: ^latest
```

Then wrap your app:
```dart
DevicePreview(
  enabled: !kReleaseMode,
  builder: (context) => const MyApp(),
)
```

### Manual Testing Sizes

```dart
// Android Studio: Device -> Cold Boot
// Phone: Pixel 5 (432x912)
// Phablet: Pixel 4a (412x915)
// Tablet: Pixel Tablet (1280x800)
```

## Responsive Checklist

- [ ] Layout works on 320px screens
- [ ] Layout works on 600px+ screens
- [ ] Layout works on 1024px+ screens
- [ ] Text is readable at all sizes
- [ ] Touch targets are ≥48dp on all sizes
- [ ] Images scale proportionally
- [ ] No horizontal scroll on any breakpoint
- [ ] Orientation changes handled smoothly
