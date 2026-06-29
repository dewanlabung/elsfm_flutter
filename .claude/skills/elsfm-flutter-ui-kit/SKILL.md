---
name: elsfm-flutter-ui-kit
description: |
  Comprehensive Flutter UI kit for building ELSFM music app screens using Material 3.
  Covers design tokens (colors, typography, spacing), reusable components (buttons, cards,
  player controls), responsive layouts, and smooth animations. Use when building new UI screens,
  styling components, or establishing design system consistency across the app.
---

# ELSFM Flutter UI Kit

Build Material 3 compliant UI for music streaming with consistent design tokens, reusable components, and smooth animations.

## Quick Start

```dart
// Use design tokens from the theme
final theme = Theme.of(context);
final primaryColor = theme.colorScheme.primary; // Spotify green
final spacing = MediaQuery.of(context).size.width * 0.04; // Responsive spacing

// Build a track card
Card(
  child: ListTile(
    leading: TrackArtwork(imageUrl: track.image),
    title: Text(track.name, style: theme.textTheme.bodyLarge),
    subtitle: Text(track.artists.map((a) => a.name).join(', ')),
  ),
)
```

## Core Principles

1. **Material 3 by Default** — Use official Material 3 widgets (AppBar, Card, FilledButton, etc.)
2. **Semantic HTML-like Structure** — Use appropriate widgets for their meaning
3. **Responsive First** — Design for 5 breakpoints: phone (320), phablet (375), tablet (768), desktop (1024), large desktop (1440)
4. **Accessible Always** — Contrast ratios >4.5:1, semantic labels, keyboard navigation
5. **Performance Matters** — Image caching, lazy loading, bounded constraints

## Design Tokens

See **[design-system.md](references/design-system.md)** for:
- Color palette (primary accent: Spotify green #1DB954)
- Typography scales (headline, title, body, label)
- Spacing system (4px base unit)
- Shadow elevations
- Border radius conventions

## Component Library

### Buttons

**[components-basics.md](references/components-basics.md)** — FilledButton, OutlinedButton, TextButton, IconButton

```dart
FilledButton(
  onPressed: () => playTrack(track),
  child: const Text('Play'),
)
```

### Cards & Containers

**[components-basics.md](references/components-basics.md)** — Track cards, album cards, playlist cards, surface containers

```dart
Card(
  child: Padding(
    padding: const EdgeInsets.all(12),
    child: Text(playlist.name),
  ),
)
```

### Player Controls

**[components-player.md](references/components-player.md)** — PlaybackControlBar, MiniPlayer, ProgressSlider, VolumeControl

```dart
PlaybackControlBar(
  track: trackInfo,
  onPlayPause: () => playerNotifier.togglePlayPause(),
  onNext: () => playerNotifier.next(),
)
```

### Navigation

**[components-navigation.md](references/components-navigation.md)** — AppBar, BottomNavigationBar, DrawerNavigationRail, Breadcrumbs

```dart
NavigationBar(
  selectedIndex: selectedIndex,
  onDestinationSelected: (index) => _selectTab(index),
  destinations: const [
    NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
  ],
)
```

## Layouts

### Responsive Patterns

**[responsive-layouts.md](references/responsive-layouts.md)** for:
- Single column (phone)
- Two column (tablet)
- Three+ column (desktop)
- Adaptive AppBars
- Bottom sheet vs dialog selection

```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < 600) {
      return ListView(children: items);
    } else {
      return GridView.count(crossAxisCount: 3, children: items);
    }
  },
)
```

## Animations

**[animations.md](references/animations.md)** for:
- Page transitions (fadeIn, slideUp, scaleIn)
- Widget entrance animations
- Micro-interactions (button press, hover)
- Scroll-triggered reveals

```dart
PageTransition(
  curve: Curves.easeOut,
  duration: const Duration(milliseconds: 300),
  child: const PlayerScreen(),
)
```

## Implementation Checklist

- [ ] Use theme.colorScheme colors (not hardcoded)
- [ ] All text styles from theme.textTheme
- [ ] Spacing uses consistent units (4px, 8px, 16px, 24px, 32px)
- [ ] Contrast ratios >4.5:1
- [ ] Semantic labels for accessibility (Semantics widget)
- [ ] Images have explicit dimensions
- [ ] No unbounded constraints in scrollables
- [ ] Animations use appropriate curves (easeOut for show, easeIn for hide)
- [ ] Dark theme tested and looks intentional

## Reference Files

| File | Purpose |
|------|---------|
| [design-system.md](references/design-system.md) | Colors, typography, spacing tokens, elevations |
| [components-basics.md](references/components-basics.md) | Buttons, cards, input fields, chip patterns |
| [components-player.md](references/components-player.md) | Player-specific UI: controls, progress, waveform |
| [components-navigation.md](references/components-navigation.md) | AppBar, navigation bars, drawers, rail |
| [animations.md](references/animations.md) | Page transitions, micro-interactions, scroll effects |
| [responsive-layouts.md](references/responsive-layouts.md) | Breakpoint strategy, adaptive widgets |

## Example: Building a Track List Screen

```dart
// See responsive-layouts.md for MediaQuery breakpoints
class TrackListScreen extends ConsumerWidget {
  final tracks = ref.watch(userLibraryTracksProvider);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('Your Library'),
          floating: true,
          snap: true,
        ),
        tracks.when(
          loading: () => SliverFillRemaining(
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => SliverFillRemaining(
            child: Center(child: Text('Error: $err')),
          ),
          data: (trackList) => SliverList.builder(
            itemCount: trackList.length,
            itemBuilder: (context, index) {
              final track = trackList[index];
              return ListTile(
                leading: TrackArtwork(imageUrl: track.image),
                title: Text(track.name),
                subtitle: Text(track.artists.map((a) => a.name).join(', ')),
                onTap: () => ref.read(playerNotifierProvider.notifier)
                    .playTrack(track),
              );
            },
          ),
        ),
      ],
    );
  }
}
```

## When to Reference This Skill

- **Building new screens** — use design tokens and component patterns
- **Styling consistency** — refer to design system for colors, fonts
- **Layout questions** — responsive patterns for different screen sizes
- **Animation implementation** — page transitions, micro-interactions
- **Accessibility audit** — contrast, semantic labels, keyboard navigation
- **Component reuse** — buttons, cards, player controls already designed
