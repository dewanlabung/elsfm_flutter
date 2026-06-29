# ELSFM Design System

Design tokens for consistent, accessible Material 3 theming.

## Color Palette

### Primary (Spotify Green)
- **Primary:** `#1DB954` (Color(0xFF1DB954))
- **On Primary:** White text/icons on primary backgrounds
- **Primary Container:** Lighter variant for secondary emphasis
- **On Primary Container:** Dark text on light backgrounds

### Neutral Grays
```dart
// Dark theme (recommended for music apps)
static const Color surface = Color(0xFF121212);      // Almost black
static const Color surfaceVariant = Color(0xFF2A2A2A);
static const Color outline = Color(0xFF6F6F6F);
static const Color onSurface = Color(0xFFFFFFFF);    // White text
```

### Semantic Colors
- **Error:** Red (#F44336) for destructive actions, validation errors
- **Success:** Green (#4CAF50) for confirmations
- **Warning:** Amber (#FFC107) for cautions

### Theme Setup

```dart
final colorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF1DB954),  // Spotify green
  brightness: Brightness.dark,         // Dark theme by default
);

final theme = ThemeData(
  useMaterial3: true,
  colorScheme: colorScheme,
  scaffoldBackgroundColor: const Color(0xFF121212),
);
```

## Typography

### Text Styles

```dart
// From theme.textTheme
textTheme.displayLarge    // 57px, bold       — Full-screen hero titles
textTheme.displayMedium   // 45px, bold       — Section headers
textTheme.headlineLarge   // 32px, bold       — Screen titles
textTheme.headlineMedium  // 28px, bold       — Subsection titles
textTheme.headlineSmall   // 24px, bold       — Card titles, headers
textTheme.titleLarge      // 22px, medium     — List item titles
textTheme.titleMedium     // 16px, medium     — Toolbar, AppBar text
textTheme.titleSmall      // 14px, medium     — Secondary headers
textTheme.bodyLarge       // 16px, regular    — Body text (default)
textTheme.bodyMedium      // 14px, regular    — Body secondary
textTheme.bodySmall       // 12px, regular    — Captions, hints
textTheme.labelLarge      // 14px, medium     — Buttons, chips, labels
textTheme.labelMedium     // 12px, medium     — Small labels
textTheme.labelSmall      // 11px, medium     — Tiny labels
```

### Font Family
- **Default:** Roboto (Material standard)
- **Override:** Configure in `ThemeData(fontFamily: 'YourFont')`

### Usage Example

```dart
Text(
  'Now Playing',
  style: Theme.of(context).textTheme.headlineSmall,
)

Text(
  track.name,
  style: Theme.of(context).textTheme.titleLarge,
)
```

## Spacing System

**Base Unit:** 4px (smallest atomic spacing)

### Standard Spacing Values
```dart
const _xs = 4.0;      // Extra small (inline padding)
const _sm = 8.0;      // Small (between elements)
const _md = 12.0;     // Medium (normal padding)
const _lg = 16.0;     // Large (container padding)
const _xl = 24.0;     // Extra large (section padding)
const _xxl = 32.0;    // 2XL (between major sections)
const _xxxl = 48.0;   // 3XL (full-screen spacing)
```

### Common Patterns

```dart
// Card padding
Padding(padding: const EdgeInsets.all(16), child: child)

// List item horizontal spacing
EdgeInsets.symmetric(horizontal: 16, vertical: 8)

// Gap between elements
SizedBox(height: 12)

// Button padding
FilledButton(
  onPressed: onPressed,
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    child: child,
  ),
)
```

### Responsive Spacing

```dart
// Responsive horizontal padding
final hPadding = MediaQuery.of(context).size.width > 600 ? 32.0 : 16.0;
Padding(padding: EdgeInsets.symmetric(horizontal: hPadding), child: child)
```

## Elevation & Shadows

### Material 3 Elevation Levels

```dart
// Elevation 0 (no shadow) — text, flat backgrounds
// Elevation 1 (minimal shadow) — outlined cards, disabled state
// Elevation 3 (subtle shadow) — default cards
// Elevation 6 (medium shadow) — pressed buttons, elevated surfaces
// Elevation 12+ (prominent shadow) — floating action buttons, menus

// Apply via Material widget
Material(
  elevation: 6,
  child: child,
)

// Or via Card (elevation 1 default)
Card(elevation: 3, child: child)
```

## Border Radius

### Standard Border Radiuses

```dart
const radiusSmall = BorderRadius.all(Radius.circular(4));    // Buttons, chips
const radiusMedium = BorderRadius.all(Radius.circular(8));   // Cards
const radiusLarge = BorderRadius.all(Radius.circular(12));   // Dialogs, sheets
const radiusMax = BorderRadius.all(Radius.circular(28));     // FAB, full radius

// Usage
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(8),
    color: Colors.blue,
  ),
  child: child,
)
```

## Animation Durations

### Standard Durations

```dart
const durationFast = Duration(milliseconds: 150);     // Micro-interactions
const durationNormal = Duration(milliseconds: 300);   // Page transitions
const durationSlow = Duration(milliseconds: 500);     // Entrance animations
const durationVslowI = Duration(milliseconds: 800);   // Slow reveals

// Usage
AnimatedContainer(
  duration: const Duration(milliseconds: 300),
  color: isHovered ? Colors.blue : Colors.grey,
  child: child,
)
```

## Animation Curves

```dart
// Show animations (elements appearing)
Curves.easeOut              // Natural deceleration
Curves.easeOutCubic         // Smooth, material-like
Curves.elasticOut           // Bouncy entrance

// Hide animations (elements leaving)
Curves.easeIn               // Natural acceleration
Curves.easeInCubic          // Smooth exit

// Scroll/continuous
Curves.easeInOut            // Smooth back-and-forth
Curves.linear               // Constant speed (spinners)
```

## Dark Theme Adjustments

ELSFM uses dark theme by default (better for music apps, reduces eye strain).

```dart
// Colors are automatically adjusted by ColorScheme
// But verify contrast in dark mode:

final colorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF1DB954),
  brightness: Brightness.dark,
);

// Verify text contrast > 4.5:1
// Use theme.colorScheme.onSurface for text (white in dark mode)
Text('Label', style: TextStyle(color: colorScheme.onSurface))
```

## Accessibility Checklist

- [ ] Contrast ratio ≥ 4.5:1 for normal text
- [ ] Contrast ratio ≥ 3:1 for large text (18pt+)
- [ ] Touch targets ≥ 48x48 dp (min. 44x44 dp)
- [ ] Text scales with system size (no fixed sizes < 12sp)
- [ ] Color not sole differentiator (use icons + text)
- [ ] Dark theme readable without burning eyes
- [ ] Icons have semantic labels (Semantics widget)

## Testing Color Contrast

Use [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/):
```
Text: #FFFFFF (white)
Background: #121212 (ELSFM dark)
Contrast: 20:1 ✅ (exceeds 4.5:1)
```
