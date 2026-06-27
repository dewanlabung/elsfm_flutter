import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../features/home/screens/home_screen.dart';
import '../features/search/screens/search_screen.dart';
import '../features/artist/screens/artist_screen.dart';
import '../features/album/screens/album_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '/artist/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id'] ?? '0');
        return ArtistScreen(artistId: id);
      },
    ),
    GoRoute(
      path: '/album/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id'] ?? '0');
        return AlbumScreen(albumId: id);
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.uri.path}'),
    ),
  ),
);
