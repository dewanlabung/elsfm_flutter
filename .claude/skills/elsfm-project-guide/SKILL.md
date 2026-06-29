---
name: elsfm-project-guide
description: |
  Comprehensive guide to the ELSFM Flutter project architecture, conventions, and development
  workflows. Covers layered architecture (presentation/domain/data), authentication strategies
  (dev mode with encrypted storage, OAuth, biometric), performance optimization, testing patterns,
  and build/deployment process. Use when onboarding, understanding project structure, or
  planning architectural decisions.
---

# ELSFM Project Guide

Complete reference for ELSFM Flutter app architecture, patterns, and workflows.

## Project Structure

```
lib/
├── main.dart                          # Entry point
├── config/
│   └── app_config.dart               # API base URLs, constants
├── data/
│   ├── models/                       # JSON-serializable models
│   │   ├── track.dart
│   │   ├── album.dart
│   │   ├── playlist.dart
│   │   └── user.dart
│   ├── services/                     # Business logic
│   │   ├── api_client.dart           # HTTP client (Dio)
│   │   ├── auth_service.dart
│   │   ├── player_service.dart
│   │   └── hive_service.dart         # Local storage
│   ├── repositories/                 # Data access layer
│   │   ├── track_repository.dart
│   │   ├── playlist_repository.dart
│   │   └── search_repository.dart
│   └── providers/                    # Riverpod providers
│       ├── api_client_provider.dart
│       └── repository_providers.dart
├── features/                          # Feature modules (layered)
│   ├── player/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── providers/
│   ├── library/
│   ├── search/
│   ├── playlist/
│   ├── auth/
│   └── profile/
├── main/                              # App shell
│   ├── app_router.dart               # GoRouter setup
│   └── app_shell.dart                # Navigation layout
├── presentation/                      # Shared UI
│   ├── widgets/
│   │   ├── error_widget.dart
│   │   ├── loading_widget.dart
│   │   └── empty_widget.dart
│   └── styles/
│       └── app_theme.dart
└── routes/
    └── app_router.dart               # Route definitions
```

## Architecture Layers

### 1. Presentation (UI)
- Screens (entire pages)
- Widgets (reusable components)
- Use Riverpod to watch state
- Never call services directly

### 2. Domain (Notifiers)
- StateNotifiers with business logic
- Handle state mutations
- Communicate with repositories

### 3. Data (Repositories)
- Repository interfaces (contract)
- Implementations using services
- Transform API responses

### 4. Services
- ApiClient (HTTP)
- AuthService (auth)
- PlayerService (audio)
- HiveService (local storage)

## Tech Stack

| Layer | Technology |
|-------|------------|
| UI Framework | Flutter 3.x |
| State Management | Riverpod |
| Navigation | GoRouter |
| HTTP | Dio |
| Local Storage | Hive, flutter_secure_storage |
| Audio | just_audio |
| DI | Riverpod providers |
| Testing | flutter_test, mockito |

## Key Patterns

### 1. Provider Pattern
- Data access abstraction
- Testable via mocks
- Dependency injection

### 2. Repository Pattern
- Encapsulate API calls
- Business logic separate from HTTP
- Consistent interface

### 3. StateNotifier Pattern
- Complex state with methods
- Immutable state (copyWith)
- Event handling

### 4. Async Pattern (AsyncValue)
- Three-way state: loading, error, data
- Automatic caching and refresh
- Built-in error handling

## Development Workflow

### 1. Creating a New Feature

```
1. Define models (data/models/feature.dart)
2. Create repository interface (data/repositories/)
3. Implement repository (data/repositories/api_*.dart)
4. Create providers (data/providers/)
5. Create notifier if complex state (features/*/providers/)
6. Build screen (features/*/screens/)
7. Add widgets (features/*/widgets/)
8. Wire route (main/app_router.dart)
9. Add tests
```

### 2. Adding API Endpoint

```
1. Define response model with fromJson/toJson
2. Add method to ApiClient
3. Create or update repository
4. Wrap in FutureProvider
5. Use in screen via ref.watch()
6. Handle AsyncValue.when()
```

### 3. Managing State

```dart
// Simple state (StateProvider)
final countProvider = StateProvider<int>((ref) => 0);
ref.read(countProvider.notifier).state = 1;

// Async state (FutureProvider)
final dataProvider = FutureProvider<Data>((ref) async {
  return await fetchData();
});

// Complex state (StateNotifierProvider)
final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  return PlayerNotifier(ref.read(playerServiceProvider));
});
```

## Authentication

### Dev Mode (Encrypted Storage)
- Auto-login with stored credentials
- Triggered by dev mode toggle
- Credentials encrypted at device level

### OAuth (Google Sign-In)
- Social login via Google
- Automatic token refresh
- Session persistence

### Biometric (Fingerprint/Face)
- Fallback after initial login
- Device-level security
- Fails gracefully if unavailable

## Performance Guidelines

- [ ] Use `.autoDispose` on all FutureProviders
- [ ] Use `.select()` to watch specific properties
- [ ] Batch-fetch instead of N+1 queries
- [ ] Cache expensive computations
- [ ] Lazy-load images
- [ ] Limit animations to critical paths
- [ ] Profile with Android Profiler
- [ ] Target <2s app startup

## Testing

```dart
// Unit test with mocks
test('loads tracks', () async {
  final container = ProviderContainer(
    overrides: [
      trackRepositoryProvider.overrideWithValue(MockTrackRepository()),
    ],
  );

  final tracks = await container.read(tracksProvider.future);
  expect(tracks.length, greaterThan(0));
});

// Widget test
testWidgets('displays tracks', (tester) async {
  await tester.pumpWidget(const App());
  expect(find.byType(TrackListItem), findsWidgets);
});
```

## Build & Release

### Android APK/AAB
```bash
flutter build apk --release              # Debug APK
flutter build appbundle --release        # Play Store
```

### iOS IPA
```bash
flutter build ios --release              # Archive for App Store
```

### Configuration
- Signing keys in local.properties (Android)
- Provisioning profiles (iOS)
- Version in pubspec.yaml

## Monitoring & Analytics

- Crashlytics for error reporting
- Firebase Analytics for events
- Sentry for performance monitoring
- Local logging for debugging

## Security Checklist

- [ ] No hardcoded secrets
- [ ] Credentials in encrypted storage
- [ ] SSL pinning configured
- [ ] Tokens refreshed before expiry
- [ ] Logout clears all local data
- [ ] Biometric auth fallback ready
- [ ] Rate limiting on API
- [ ] Input validation client + server

## Reference Files

| File | Purpose |
|------|---------|
| [architecture-overview.md](references/architecture-overview.md) | Layered design, data flow |
| [file-structure.md](references/file-structure.md) | Directory organization |
| [authentication.md](references/authentication.md) | Auth flows and credential storage |
| [performance-optimization.md](references/performance-optimization.md) | Perf tuning, profiling |
| [testing-guide.md](references/testing-guide.md) | Unit, widget, integration tests |
| [build-deployment.md](references/build-deployment.md) | Build process, store submission |

## Quick Commands

```bash
# Development
flutter run -d <device>
flutter run --debug

# Build
flutter build apk --release
flutter build appbundle --release
flutter build ios --release

# Analysis
dart analyze
dart format .

# Testing
flutter test
flutter test --coverage

# Clean
flutter clean
```

## Common Issues

**Issue:** Type errors after model changes
**Solution:** Run `dart run build_runner build` if using code generation

**Issue:** App crashes on startup
**Solution:** Clear app cache, run `flutter clean`, rebuild

**Issue:** Slow image loading
**Solution:** Use `CachedNetworkImage`, add `fetchPriority`, verify network

**Issue:** Memory leaks
**Solution:** Use `.autoDispose`, check StreamSubscriptions closed

## When to Reference This Skill

- **Onboarding new developer** → Start with architecture overview
- **Adding new feature** → Follow development workflow
- **Performance issues** → Check performance-optimization.md
- **Build/deployment** → See build-deployment.md
- **Testing** → Reference testing-guide.md
- **Architecture decisions** → Review architecture-overview.md
