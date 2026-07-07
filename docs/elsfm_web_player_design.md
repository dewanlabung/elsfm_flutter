# ELSFM Web Player Design Reference
> Scraped from https://www.elsfm.com — July 2026

## CSS Theme Variables (BeMusic/Laravel)
```
--be-primary:        104 159 56    → rgb(104,159,56) = #689F38  (GREEN)
--be-on-primary:     255 255 255   → white text on primary
--be-primary-light:  180 207 156   → #B4CF9C  (light green)
--be-primary-dark:    27  27  27   → #1B1B1B

--be-bg:              35  35  44   → #23232C  (main bg, dark purple-grey)
--be-bg-elevated:     18  18  18   → #121212  (very dark - navbar/elevated areas)
--be-bg-alt:          30  30  38   → #1E1E26  (alternate bg)
--be-paper:           35  35  44   → #23232C  (card/paper bg)
--be-bg-chip:         53  53  65   → #353541  (chip/tag bg)

--be-fg-base:        255 255 255   → white
--be-text-main-opacity:    100%
--be-text-muted-opacity:    70%

--be-hover-opacity:          8%
--be-focus-opacity:         12%
--be-selected-opacity:      16%
--be-divider-opacity:       12%
--be-disabled-fg-opacity:   30%
--be-disabled-bg-opacity:   12%

--be-input-radius:   0.5rem
--be-button-radius:  0.5rem
--be-panel-radius:   0.75rem
```

## Flutter Color Map
```dart
static const Color primary        = Color(0xFF689F38); // #689F38
static const Color primaryLight   = Color(0xFFB4CF9C);
static const Color background     = Color(0xFF23232C); // main bg
static const Color backgroundElevated = Color(0xFF121212); // navbar
static const Color backgroundAlt  = Color(0xFF1E1E26);
static const Color paper          = Color(0xFF23232C);
static const Color chip           = Color(0xFF353541);
static const Color onPrimary      = Colors.white;
static const Color textMain       = Colors.white;
static const Color textMuted      = Color(0xB3FFFFFF); // 70% white
static const Color divider        = Color(0x1FFFFFFF); // 12% white
static const Color hover          = Color(0x14FFFFFF); // 8% white
```

## Page Layout
```
┌─────────────────────────────────────────────┐
│  TOP NAVBAR (59px)                          │  bg-elevated (#121212), border-bottom
│  [Logo]  [Search]  [Login/Profile]          │
├─────────────────────────────────────────────┤
│                                             │
│  MAIN CONTENT (flex-auto)                   │  bg (#23232C)
│  ┌─────────────────────────────────────┐    │
│  │ web-player-container p-16 md:p-30   │    │
│  │  [blurred album art gradient bg]    │    │
│  │  <h1> Playlist/Album Title          │    │
│  │  [Play All] [Shuffle]               │    │
│  │  ── Track List ──────────────────── │    │
│  │  [img 42x42] Title  Artist  3:24 ⋮ │    │
│  └─────────────────────────────────────┘    │
│                                             │
├─────────────────────────────────────────────┤
│  PLAYER BAR (130px)                         │
│  m-4 rounded-panel (0.75rem) border shadow  │  bg-elevated (#121212)
│  ┌──────────────────────────────────────┐   │
│  │ [Art36] TrackTitle    [⏮][▶️][⏭][👤] │   │
│  │         ArtistName                   │   │
│  └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

## Player Bar Details
- Container: `m-4 rounded-panel border border-divider-lighter shadow dark:border-divider dark:bg-elevated`
- Inner layout: `relative flex items-center justify-between gap-24 px-10 py-8`
- **Left**: `flex min-w-0 flex-auto items-center gap-10`
  - Album art: `h-36 w-36 rounded object-cover` (36x36px, 4px radius)
  - Title: `overflow-ellipsis text-sm font-medium`
  - Artist: `overflow-ellipsis text-xs text-muted`
- **Center**: `flex items-center justify-center`
  - Buttons: `h-42 w-42` rounded-button (42x42px touch targets)
  - Play/Pause button custom SVG icons
- **Right**: `flex items-center gap-10`
  - Avatar/profile button

## Track List Item (compact-grid)
```html
<div class="flex snap-start items-center gap-16 border-t py-10">
  <div class="group relative h-42 w-42 flex-shrink-0 cursor-pointer overflow-hidden rounded-md">
    <img ...>
    <!-- Hover overlay: bg-black/50 with play button -->
  </div>
  <div class="flex-auto overflow-hidden">
    <div class="text-sm font-medium overflow-ellipsis">Track Title</div>
    <div class="text-xs text-muted overflow-ellipsis">Artist Name</div>
  </div>
  <div class="text-xs text-muted">3:24</div>
  <button aria-label="More options">⋮</button>
</div>
```

## Content Cards (default-grid)
- Grid item: `group relative isolate w-full`
- Cover: `aspect-square w-full rounded-panel shadow-md`
- Title below: `text-sm font-medium`
- Hover state: dark overlay with play button

## Tailwind Custom Classes (mapped)
| Class           | Value                          |
|----------------|-------------------------------|
| `rounded-panel` | `border-radius: 0.75rem`      |
| `rounded-button`| `border-radius: 0.5rem`       |
| `bg-elevated`  | `background: rgb(18,18,18)`   |
| `bg-hover`     | `background: rgba(255,255,255,0.08)` |
| `text-muted`   | `color: rgba(255,255,255,0.70)` |
| `text-main`    | `color: rgb(255,255,255)`     |
| `border-divider`| `border: 1px solid rgba(255,255,255,0.12)` |

## Icons Used (SVG paths in player bar)
- Previous: `M25.13 6.79C25.58 6.46 26.20 6.77 26.20 7.32V24.68...`
- Play:     `M10.67 6.65C10.67 6.11 11.29 5.79 11.73 6.12L24.38 15.46...`
- Next:     `M6.40 6.79C5.96 6.46 5.33 6.77 5.33 7.32V24.68...`

## Key Design Observations
1. **No sidebar** — single column, mobile-first
2. **Player bar has rounded corners + margin** — floats above page edge, not edge-to-edge
3. **Dark theme dominant** — bg #23232C, elevated bg #121212
4. **Green primary** — #689F38 (Tailwind green-700ish)
5. **Compact layout** — lots of small text (xs/sm), tight padding
6. **Blurred album art** as page background (backdrop blur gradient)
7. **42px touch targets** for all buttons
8. **36px album art** in mini player bar
