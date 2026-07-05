import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/services/hive_service.dart';
import 'features/auth/models/auth_state.dart';
import 'features/auth/providers/auth_notifier.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/settings/providers/theme_provider.dart';
import 'main/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();

  // Note: AudioService initialization happens lazily when playerProvider is accessed
  // This avoids issues with service initialization during app startup

  runApp(
    const ProviderScope(
      child: ElsfmApp(),
    ),
  );
}

class ElsfmApp extends ConsumerWidget {
  const ElsfmApp({super.key});


  static ThemeData _buildTheme(Brightness brightness) => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1DB954),
          brightness: brightness,
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Show loading spinner while restoring session
    if (authState.state == AuthState.authenticating) {
      return MaterialApp(
        title: 'ELSFM',
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        themeMode: themeMode,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Show login screen for unauthenticated / error states
    if (authState.state != AuthState.authenticated) {
      return MaterialApp(
        title: 'ELSFM',
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        themeMode: themeMode,
        home: const LoginScreen(),
      );
    }

    // Authenticated: use Phase 3 router with ShellRoute, bottom nav, mini-player
    return MaterialApp.router(
      title: 'ELSFM',
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
