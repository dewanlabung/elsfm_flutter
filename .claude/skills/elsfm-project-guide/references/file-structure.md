# File Organization

Directory structure and naming conventions.

## Root Structure

```
elsfm_flutter/
├── lib/
├── test/
├── analysis_options.yaml
├── pubspec.yaml
├── CLAUDE.md
└── README.md
```

## lib/ Structure

```
lib/
├── main.dart                    # Entry point
├── config/
│   └── app_config.dart         # Constants, URLs
├── data/
│   ├── models/                 # JSON models
│   ├── services/               # Business logic
│   ├── repositories/           # Data access
│   └── providers/              # DI providers
├── features/
│   ├── auth/                   # Feature module
│   │   ├── screens/
│   │   ├── widgets/
│   │   ├── providers/
│   │   └── models/
│   ├── player/
│   ├── library/
│   ├── search/
│   ├── playlist/
│   └── profile/
├── main/
│   ├── app_router.dart         # GoRouter
│   └── app_shell.dart          # Navigation layout
├── presentation/
│   ├── widgets/                # Shared UI
│   └── styles/                 # Theme, colors
└── routes/
    └── app_router.dart
```

## Naming Conventions

- **Files:** snake_case (`my_file.dart`)
- **Classes:** PascalCase (`MyClass`)
- **Functions:** camelCase (`myFunction()`)
- **Variables:** camelCase (`myVariable`)
- **Constants:** camelCase (`const myConstant`)
- **Providers:** `*Provider` (`userProvider`)
- **Notifiers:** `*Notifier` (`PlayerNotifier`)

## Feature Module Structure

Each feature is self-contained:

```
features/player/
├── screens/
│   └── now_playing_screen.dart
├── widgets/
│   ├── playback_controls.dart
│   └── progress_slider.dart
├── providers/
│   └── player_notifier.dart
└── models/
    └── player_state.dart
```

## Imports

- **Absolute imports:** Use for data layer (models, services, repos)
- **Relative imports:** Use within features for widgets

```dart
// Absolute (data layer)
import 'package:elsfm_flutter/data/models/track.dart';
import 'package:elsfm_flutter/data/repositories/track_repository.dart';

// Relative (within feature)
import '../widgets/track_card.dart';
import '../providers/player_notifier.dart';
```

## File Size Guidelines

- Screens: 200-300 lines max
- Widgets: 100-200 lines max
- Providers: 150-250 lines max
- Models: 100-150 lines max
- Services: 300+ lines OK (complex logic)

Split larger files into smaller modules.
