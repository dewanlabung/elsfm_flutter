# Animations

Material 3 animations for page transitions, micro-interactions, and entrance effects.

## Page Transitions

### Navigate with Custom Transition

```dart
// Using go_router with custom transition
GoRoute(
  path: '/player',
  pageBuilder: (context, state) => CustomTransitionPage(
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    child: const NowPlayingScreen(),
  ),
)
```

### Fade Transition (Recommended)

Smooth fade for screen transitions. Best for music app aesthetics.

```dart
FadeTransition(
  opacity: animation,
  child: child,
)
```

### Slide Up Transition

Push new screen up from bottom.

```dart
SlideTransition(
  position: animation.drive(
    Tween(begin: const Offset(0, 1), end: Offset.zero).chain(
      CurveTween(curve: Curves.easeOut),
    ),
  ),
  child: child,
)
```

### Scale Transition

Grow screen from center.

```dart
ScaleTransition(
  scale: animation.drive(
    Tween(begin: 0.8, end: 1.0).chain(
      CurveTween(curve: Curves.easeOut),
    ),
  ),
  child: child,
)
```

## Micro-Interactions

### Button Press Feedback

Built into Material buttons automatically, but can customize:

```dart
FilledButton(
  onPressed: onPressed,
  style: FilledButton.styleFrom(
    animationDuration: const Duration(milliseconds: 200),
  ),
  child: const Text('Play'),
)
```

### Icon Rotation (Play/Pause)

```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 200),
  transitionBuilder: (child, animation) {
    return ScaleTransition(scale: animation, child: child);
  },
  child: Icon(
    playerState.isPlaying ? Icons.pause : Icons.play_arrow,
    key: ValueKey<bool>(playerState.isPlaying),
  ),
)
```

### Container Color Change

```dart
AnimatedContainer(
  duration: const Duration(milliseconds: 300),
  color: isFavorite ? Colors.red : Colors.grey,
  child: child,
)
```

## Entrance Animations

### Fade In

Gradually reveal element.

```dart
class FadeInWidget extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const FadeInWidget({
    required this.child,
    this.delay = Duration.zero,
    super.key,
  });

  @override
  State<FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _controller, child: widget.child);
  }
}

// Usage
FadeInWidget(
  delay: const Duration(milliseconds: 100),
  child: Text('Fade in with delay'),
)
```

### Slide In from Left

```dart
class SlideInWidget extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const SlideInWidget({
    required this.child,
    this.delay = Duration.zero,
    super.key,
  });

  @override
  State<SlideInWidget> createState() => _SlideInWidgetState();
}

class _SlideInWidgetState extends State<SlideInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _controller.drive(
        Tween(begin: const Offset(-1, 0), end: Offset.zero).chain(
          CurveTween(curve: Curves.easeOut),
        ),
      ),
      child: widget.child,
    );
  }
}
```

### Staggered List Animation

Animate list items in sequence.

```dart
class StaggeredListView extends StatefulWidget {
  final List<Widget> items;

  const StaggeredListView({required this.items, super.key});

  @override
  State<StaggeredListView> createState() => _StaggeredListViewState();
}

class _StaggeredListViewState extends State<StaggeredListView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final itemAnimation = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(
              (index * 0.1).clamp(0.0, 1.0),
              ((index + 1) * 0.1).clamp(0.0, 1.0),
              curve: Curves.easeOut,
            ),
          ),
        );

        return FadeTransition(
          opacity: itemAnimation,
          child: SlideTransition(
            position: itemAnimation.drive(
              Tween(begin: const Offset(0, 0.2), end: Offset.zero),
            ),
            child: widget.items[index],
          ),
        );
      },
    );
  }
}
```

## Standard Curves

### Exit (Hide)
```dart
Curves.easeIn              // Accelerating from zero velocity
Curves.easeInCubic         // Smooth cubic easing
```

### Entrance (Show)
```dart
Curves.easeOut             // Decelerating to zero velocity
Curves.easeOutCubic        // Smooth cubic easing (recommended)
Curves.elasticOut          // Bouncy entrance (playful)
```

### Bidirectional
```dart
Curves.easeInOut           // Start slow, end slow
Curves.easeInOutCubic      // Smooth cubic both ways
```

### Continuous
```dart
Curves.linear              // Constant velocity
Curves.easeInOutQuad       // Gentle ease
```

## Material 3 Motion Principles

1. **Fast:** 100-150ms for micro-interactions (hover, press)
2. **Normal:** 200-300ms for page transitions
3. **Slow:** 400-500ms for entrance animations
4. **Very Slow:** 600ms+ for complex, multi-stage animations

## Animation Duration Reference

```dart
const durationFast = Duration(milliseconds: 150);      // Button press
const durationNormal = Duration(milliseconds: 300);    // Page transition
const durationSlow = Duration(milliseconds: 500);      // Entrance effect
const durationVerySlow = Duration(milliseconds: 800);  // Complex animation
```

## Avoid Over-Animation

- Don't animate every widget
- Limit animations to 300ms max (except entrance)
- Use animations to clarify flow, not distract
- Disable animations on low-end devices or when system prefers reduced motion

## Reduce Motion Support

Respect user's accessibility preferences:

```dart
final mediaQuery = MediaQuery.of(context);
final reducedMotion = mediaQuery.disableAnimations;

return AnimatedContainer(
  duration: reducedMotion
      ? Duration.zero
      : const Duration(milliseconds: 300),
  color: isFavorite ? Colors.red : Colors.grey,
  child: child,
)
```
