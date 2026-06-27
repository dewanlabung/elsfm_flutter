# Dart Compiler Crash Workaround

## Issue

The ELSFM Flutter app crashes during compilation with Dart 3.12.x on macOS:

```
Unhandled exception:
Bus error: 10(10), si_code=BUS_ADRERR(2)
The Dart compiler exited unexpectedly.
```

**Root Cause:** Dart 3.12.0–3.12.2 have a known JIT compiler bug on macOS where aggressive optimization passes in `_BufferingStreamSubscription._checkState` cause bus errors during kernel compilation.

**References:**
- Dart Issue #57719: JIT compiler optimization crash on macOS
- Affects Flutter 3.44.0–3.44.4 (which ship with Dart 3.12.x)

## Workaround

Set the `DART_VM_OPTIONS` environment variable to disable aggressive JIT optimizations:

```bash
export DART_VM_OPTIONS="--use-slow-path"
flutter run -d <device_id>
```

The `--use-slow-path` flag bypasses the problematic optimization passes while still allowing normal app execution. There is a negligible performance impact since the app runs in JIT mode anyway (debug builds).

## How to Apply

### One-Time Fix
```bash
export DART_VM_OPTIONS="--use-slow-path"
flutter run
```

### Persistent Setup
Add to your shell profile (`~/.zshrc`, `~/.bashrc`, etc.):
```bash
export DART_VM_OPTIONS="--use-slow-path"
```

### Project-Specific
Source the included `.env.dart` file before building:
```bash
source .env.dart
flutter run
```

## Long-Term Solution

Upgrade to Flutter 3.45.0+ or Dart 3.13.0+ once available and stable. These versions include the fix for this compiler issue.

## Verification

The build should succeed with:
```
✓ Built build/app/outputs/flutter-apk/app-debug.apk
Syncing files to device...
A Dart VM Service on <device> is available at: http://...
```

If you still see bus error crashes, verify:
1. `echo $DART_VM_OPTIONS` shows `--use-slow-path`
2. No stale `.dart_tool/` cache: `flutter clean`
3. Flutter version: `flutter --version` (should be 3.44.x with Dart 3.12.x)
