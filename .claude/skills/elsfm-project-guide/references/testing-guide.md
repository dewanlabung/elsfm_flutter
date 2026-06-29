# Testing Guide

Unit, widget, and integration tests.

## Unit Tests

```dart
test('PlayerNotifier plays track', () async {
  final mockService = MockPlayerService();
  final notifier = PlayerNotifier(mockService);

  await notifier.play();

  expect(notifier.state.isPlaying, true);
  expect(mockService.playWasCalled, true);
});
```

## Widget Tests

```dart
testWidgets('displays tracks', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        trackRepositoryProvider.overrideWithValue(MockTrackRepository()),
      ],
      child: const MaterialApp(home: TrackListScreen()),
    ),
  );

  expect(find.byType(TrackListItem), findsWidgets);
  expect(find.byType(CircularProgressIndicator), findsNothing);
});
```

## Integration Tests

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full user flow', (tester) async {
    await tester.pumpWidget(const MyApp());

    // Login
    await tester.tap(find.byIcon(Icons.login));
    await tester.enterText(find.byType(TextField).first, 'user@example.com');
    await tester.tap(find.byText('Login'));
    await tester.pumpAndSettle();

    // Play track
    expect(find.byType(TrackList), findsOneWidget);
  });
}
```

## Test Structure

```
test/
├── unit/
│   ├── data/
│   │   └── repositories/
│   └── features/
│       └── player/
├── widget/
│   ├── screens/
│   └── widgets/
└── integration/
    └── full_flow_test.dart
```

## Run Tests

```bash
# All tests
flutter test

# Specific file
flutter test test/unit/data/repositories/track_repository_test.dart

# With coverage
flutter test --coverage

# Watch mode
flutter test --watch
```

## Best Practices

- ✅ Test behavior, not implementation
- ✅ Use descriptive test names
- ✅ Mock external dependencies
- ✅ Test error cases
- ✅ Use `pumpAndSettle()` for animations
- ❌ Don't test Flutter framework
- ❌ Don't mock internal classes
- ❌ Don't test private methods directly
