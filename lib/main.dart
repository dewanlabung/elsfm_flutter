import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    return MaterialApp.router(
      title: 'ELSFM',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1DB954), // Spotify green
          brightness: Brightness.dark,
        ),
      ),
      routerConfig: appRouter,
    );
  }
}
