import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'app_shell.dart';
import '../features/home/screens/home_screen.dart';
import '../features/search/screens/search_screen.dart';
import '../features/library/screens/library_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/player/screens/now_playing_screen.dart';

/// App router configuration with all routes
final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return AppShell(child: child, routerState: state);
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/library',
          builder: (context, state) => const LibraryScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/now-playing',
          builder: (context, state) => const NowPlayingScreen(),
        ),
      ],
    ),
  ],
);
