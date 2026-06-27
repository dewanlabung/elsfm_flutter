import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    const ProviderScope(
      child: ElsfmApp(),
    ),
  );
}

class ElsfmApp extends StatelessWidget {
  const ElsfmApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ELSFM',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1DB954), // Spotify green
          brightness: Brightness.dark,
        ),
      ),
      home: const Scaffold(
        body: Center(
          child: Text('ELSFM — Loading...'),
        ),
      ),
    );
  }
}
