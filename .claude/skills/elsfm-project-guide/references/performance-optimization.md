# Performance Optimization

Improve app speed and reduce memory usage.

## Startup Time (<2s target)

1. **Lazy initialize services** — Don't load on app start
2. **Async main()** — Initialize only essentials
3. **Preload critical data** — User data, config

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();  // Lightweight, fast
  // Don't init AudioService here (lazy)
  runApp(const MyApp());
}
```

## Image Loading

```dart
// Explicit dimensions
Image.network(
  imageUrl,
  width: 200,
  height: 200,
  fit: BoxFit.cover,
  loadingBuilder: (context, child, progress) {
    return progress == null ? child : Placeholder();
  },
)

// Caching
import 'package:cached_network_image/cached_network_image.dart';
CachedNetworkImage(imageUrl: imageUrl)

// Lazy loading
loading: LazyLoad.lazy,
```

## Memory Management

- Use `.autoDispose` on all FutureProviders
- Clear large caches when not needed
- Dispose StreamSubscriptions
- Don't keep references to BuildContext

```dart
final tracksProvider = FutureProvider.autoDispose<List<Track>>((ref) {
  // Auto-cleared when unmounted
  return fetchTracks();
});
```

## Frame Rate

- Animate compositor-friendly properties only (transform, opacity)
- Avoid animating layout-bound properties (width, height)
- Use `will-change` (Flutter: `willChange` not needed)

## Profiling

```bash
# Android Profiler
flutter run --profile

# DevTools
flutter pub global activate devtools
devtools

# Check FPS
flutter run -v | grep "Skipped|Frame"
```

## Targets

| Metric | Target |
|--------|--------|
| Startup | <2s |
| Track Load | <500ms |
| Frame Rate | 60fps |
| Memory | <200MB |
| APK Size | <100MB |

## Checklist

- [ ] All images have explicit dimensions
- [ ] No N+1 queries
- [ ] Large lists use ListView (lazy)
- [ ] Heavy computations memoized
- [ ] Animations use fast curves
- [ ] Profiled with DevTools
