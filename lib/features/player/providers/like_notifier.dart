import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/providers/api_client_provider.dart';
import '../../../data/services/api_client.dart';
import '../../auth/providers/auth_notifier.dart';

class LikeNotifier extends StateNotifier<Set<int>> {
  final ApiClient _api;
  final int? _userId;

  LikeNotifier(this._api, this._userId) : super({}) {
    if (_userId != null) _load();
  }

  Future<void> _load() async {
    try {
      final result = await _api.getLikedTracks(_userId!);
      state = result.data.map((t) => t.id).toSet();
    } catch (_) {}
  }

  bool isLiked(int trackId) => state.contains(trackId);

  Future<void> toggle(int trackId) async {
    if (_userId == null) return;
    final wasLiked = state.contains(trackId);
    // Optimistic update
    if (wasLiked) {
      state = {...state}..remove(trackId);
    } else {
      state = {...state, trackId};
    }
    try {
      if (wasLiked) {
        await _api.unlikeTrack(_userId!, trackId);
      } else {
        await _api.likeTrack(_userId!, trackId);
      }
    } catch (_) {
      // Revert on failure
      if (wasLiked) {
        state = {...state, trackId};
      } else {
        state = {...state}..remove(trackId);
      }
    }
  }
}

final likeNotifierProvider = StateNotifierProvider<LikeNotifier, Set<int>>((ref) {
  final api = ref.watch(apiClientProvider);
  final userId = ref.watch(authNotifierProvider).user?.id;
  return LikeNotifier(api, userId);
});
