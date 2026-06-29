import 'package:go_router/go_router.dart';
import 'app_shell.dart';
import '../features/home/screens/home_screen.dart';
import '../features/search/screens/search_screen.dart';
import '../features/library/screens/library_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/player/screens/now_playing_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/playlists/screens/playlist_detail_screen.dart';
import '../features/album/screens/album_detail_screen.dart';
import '../features/artist/screens/artist_detail_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';

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
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/playlist/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id'] ?? '0');
            return PlaylistDetailScreen(playlistId: id);
          },
        ),
        GoRoute(
          path: '/album/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id'] ?? '0');
            return AlbumDetailScreen(albumId: id);
          },
        ),
        GoRoute(
          path: '/artist/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id'] ?? '0');
            return ArtistDetailScreen(artistId: id);
          },
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
      ],
    ),
  ],
);
