import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import './http_client_provider.dart';

/// Construct an [ApiClient] directly from a [Dio] instance.
/// Used by code that already holds a resolved [Dio] (e.g. fire-and-forget
/// calls inside notifiers that cannot use async providers synchronously).
ApiClient apiClientFromDio(Dio dio) => ApiClient(dio);

/// Async provider — use this in FutureProviders and AsyncNotifiers.
final apiClientFutureProvider = FutureProvider<ApiClient>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return ApiClient(dio);
});

/// Sync provider — unwraps [dioProvider] for use in sync [Provider]s.
/// Throws during the brief window while [dioProvider] is still initialising.
/// Callers should use [apiClientFutureProvider] when possible, or guard with
/// [dioProvider].when() / [AsyncValue.whenData] to avoid a synchronous throw.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ref.watch(dioProvider).when(
    data: (dio) => ApiClient(dio),
    loading: () => throw StateError('Dio not ready yet'),
    error: (err, _) => throw err,
  );
});
