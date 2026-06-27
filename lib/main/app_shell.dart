import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/player/widgets/mini_player.dart';

/// Main app shell with bottom navigation and persistent mini player
class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  final GoRouterState routerState;

  const AppShell({
    required this.child,
    required this.routerState,
    super.key,
  });

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;

  static const List<String> _routes = [
    '/home',
    '/search',
    '/library',
    '/recommendations',
  ];

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final path = widget.routerState.uri.path;
    final idx = _routes.indexWhere((r) => path.startsWith(r));
    if (idx >= 0 && idx != _selectedIndex) {
      setState(() => _selectedIndex = idx);
    }
  }

  void _selectTab(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: widget.child),
          MiniPlayer(
            onExpanded: () => context.push('/now-playing'),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_border),
            selectedIcon: Icon(Icons.star),
            label: 'For You',
          ),
        ],
      ),
    );
  }
}
