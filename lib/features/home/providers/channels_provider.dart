import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/channel.dart';
import '../../../data/providers/api_client_provider.dart';

final channelsProvider = FutureProvider<List<Channel>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.getChannels();
  return response.data;
});
