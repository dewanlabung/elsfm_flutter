import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import './http_client_provider.dart';

final apiClientProvider = Provider((ref) {
  return ref.watch(dioProvider).when(
    data: (dio) => ApiClient(dio),
    loading: () => throw Exception('Dio not ready'),
    error: (err, st) => throw err,
  );
});
