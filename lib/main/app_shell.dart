import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/player/widgets/mini_player.dart';
import '../features/auth/providers/auth_notifier.dart';
import '../features/auth/models/auth_state.dart';

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
    '/profile',
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
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    return Scaffold(
      drawer: _AppDrawer(
        user: user,
        selectedRoute: widget.routerState.uri.path,
        onNavigate: (route) {
          Navigator.pop(context); // close drawer
          context.go(route);
        },
      ),
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
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ── Side drawer ───────────────────────────────────────────────────────────────

class _AppDrawer extends ConsumerWidget {
  final dynamic user;
  final String selectedRoute;
  final void Function(String route) onNavigate;

  const _AppDrawer({
    required this.user,
    required this.selectedRoute,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          DrawerHeader(
            decoration: BoxDecoration(color: colorScheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage:
                      user?.avatar != null ? NetworkImage(user!.avatar!) : null,
                  child: user?.avatar == null
                      ? const Icon(Icons.person, size: 32)
                      : null,
                ),
                const SizedBox(height: 10),
                Text(
                  user?.name ?? 'Guest',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (user?.email != null)
                  Text(
                    user!.email!,
                    style: TextStyle(
                      color: colorScheme.onPrimary.withOpacity(0.75),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),

          // ── Navigation items ─────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerItem(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  selected: selectedRoute.startsWith('/home'),
                  onTap: () => onNavigate('/home'),
                ),
                _DrawerItem(
                  icon: Icons.search,
                  label: 'Search',
                  selected: selectedRoute.startsWith('/search'),
                  onTap: () => onNavigate('/search'),
                ),
                _DrawerItem(
                  icon: Icons.library_music_outlined,
                  label: 'Library',
                  selected: selectedRoute.startsWith('/library'),
                  onTap: () => onNavigate('/library'),
                ),
                _DrawerItem(
                  icon: Icons.download_outlined,
                  label: 'Downloads',
                  selected: selectedRoute.startsWith('/downloads'),
                  onTap: () => onNavigate('/downloads'),
                ),
                const Divider(),
                _DrawerItem(
                  icon: Icons.person_outline,
                  label: 'Profile',
                  selected: selectedRoute.startsWith('/profile'),
                  onTap: () => onNavigate('/profile'),
                ),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  selected: selectedRoute.startsWith('/settings'),
                  onTap: () => onNavigate('/settings'),
                ),
              ],
            ),
          ),

          // ── Footer ───────────────────────────────────────────────────────
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline, size: 20),
            title: const Text('ELSFM v1.0.0', style: TextStyle(fontSize: 13)),
            dense: true,
            onTap: () {},
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: selected,
      selectedTileColor:
          Theme.of(context).colorScheme.primary.withOpacity(0.1),
      selectedColor: Theme.of(context).colorScheme.primary,
      onTap: onTap,
    );
  }
}
