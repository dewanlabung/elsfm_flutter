import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/channel.dart';
import '../../../data/providers/api_client_provider.dart';
import '../../auth/providers/auth_notifier.dart';

final channelsProvider = FutureProvider<List<Channel>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final authState = ref.watch(authNotifierProvider);

  // Get the user ID from auth state
  final userId = authState.user?.id;

  final response = await apiClient.getChannels(userId: userId);
  return response.data;
});
