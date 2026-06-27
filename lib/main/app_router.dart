import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'app_shell.dart';
import '../features/search/screens/search_screen.dart';
import '../features/library/screens/library_screen.dart';
import '../features/recommendations/screens/recommendations_screen.dart';
import '../features/player/screens/now_playing_screen.dart';

/// App router configuration with all routes
final appRouter = GoRouter(
  initialLocation: '/search',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return AppShell(child: child, routerState: state);
      },
      routes: [
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/library',
          builder: (context, state) => const LibraryScreen(),
        ),
        GoRoute(
          path: '/recommendations',
          builder: (context, state) => const RecommendationsScreen(),
        ),
        GoRoute(
          path: '/now-playing',
          builder: (context, state) => const NowPlayingScreen(),
        ),
      ],
    ),
  ],
);
