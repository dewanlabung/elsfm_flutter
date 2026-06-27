import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/models/auth_state.dart';
import 'features/auth/providers/auth_notifier.dart';
import 'features/auth/screens/login_screen.dart';
import 'routes/app_router.dart';

void main() {
  runApp(
    const ProviderScope(
      child: ElsfmApp(),
    ),
  );
}

class ElsfmApp extends StatelessWidget {
  const ElsfmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ELSFM',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1DB954),
          brightness: Brightness.dark,
        ),
      ),
      home: const ElsfmHome(),
    );
  }
}

class ElsfmHome extends ConsumerWidget {
  const ElsfmHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    if (authState.state == AuthState.authenticating) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (authState.state == AuthState.authenticated) {
      return MaterialApp.router(
        title: 'ELSFM',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1DB954),
            brightness: Brightness.dark,
          ),
        ),
        routerConfig: appRouter,
      );
    }

    return const LoginScreen();
  }
}
