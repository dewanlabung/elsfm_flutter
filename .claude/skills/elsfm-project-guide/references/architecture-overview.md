# Architecture Overview

ELSFM uses clean layered architecture with clear separation of concerns.

## Layers

```
Presentation Layer
├── Screens (pages)
├── Widgets (reusable UI)
└── Providers (Riverpod watchers)
         ↓
Domain Layer
├── StateNotifiers (business logic)
├── Models (data classes)
└── Notifier logic
         ↓
Data Layer
├── Repositories (data access)
├── Services (HTTP, auth, storage)
└── Models (serialization)
         ↓
Infrastructure
├── API client (Dio)
├── Local storage (Hive)
└── Device services (audio, biometrics)
```

## Data Flow

```
UI (Screen) watches Provider
  ↓
Provider watches StateNotifier
  ↓
StateNotifier calls Repository
  ↓
Repository calls Service
  ↓
Service (API, storage, etc.)
  ↓
Response → Model → NotifierState
  ↓
Screen rebuilds
```

## Dependency Injection

All dependencies injected via Riverpod:

```dart
// Service
final playerServiceProvider = Provider<PlayerService>((ref) {
  return PlayerService();
});

// Repository
final trackRepositoryProvider = Provider<TrackRepository>((ref) {
  return ApiTrackRepository(ref.read(apiClientProvider));
});

// Notifier
final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  return PlayerNotifier(ref.read(playerServiceProvider));
});

// Screen
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Never instantiate - get from provider
    final player = ref.watch(playerProvider);
  }
}
```

## Benefits

- **Testable:** Mock any layer
- **Maintainable:** Clear responsibility
- **Reusable:** Providers everywhere
- **Scalable:** Add features without affecting core
- **Decoupled:** Layers don't know about each other

## Key Decisions

1. **StateNotifier for complex state** — PlayerNotifier manages play state
2. **FutureProvider for API calls** — Auto-caching, auto-refresh
3. **Repository pattern** — Encapsulate data access
4. **Riverpod DI** — No service locators, compile-time safe
5. **Immutable state** — copyWith() for updates
