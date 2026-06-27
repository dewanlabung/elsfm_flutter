import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/providers/api_client_provider.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final query = ref.watch(searchQueryProvider);

  if (query.isEmpty) {
    return {};
  }

  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.search(query: query);
  return response;
});
