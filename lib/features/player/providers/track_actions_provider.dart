import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/track.dart';
import '../../../data/providers/http_client_provider.dart';
import '../models/track_action.dart';
import '../services/track_actions_service.dart';

final trackActionsServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider).valueOrNull;
  return TrackActionsService(dio: dio);
});

/// Provider to handle share action
final shareTrackProvider = FutureProvider.family<void, Track>((ref, track) async {
  final service = ref.watch(trackActionsServiceProvider);
  return service.shareTrack(track);
});

/// Provider to handle download action
final downloadTrackProvider = FutureProvider.family<bool, Track>((ref, track) async {
  final service = ref.watch(trackActionsServiceProvider);
  return service.downloadTrack(track);
});

/// Provider to handle add to playlist action
final addTrackToPlaylistProvider = FutureProvider.family<void, (Track, String)>(
  (ref, params) async {
    final service = ref.watch(trackActionsServiceProvider);
    final (track, playlistId) = params;
    return service.addTrackToPlaylist(track, playlistId);
  },
);

/// Provider to handle add to queue action
final addTrackToQueueProvider = FutureProvider.family<void, Track>((ref, track) async {
  final service = ref.watch(trackActionsServiceProvider);
  return service.addTrackToQueue(track);
});

/// Provider for available track actions
final availableTrackActionsProvider = Provider<List<TrackAction>>((ref) {
  return [
    TrackAction.addToPlaylist,
    TrackAction.addToQueue,
    TrackAction.share,
    TrackAction.download,
    TrackAction.viewDetails,
    TrackAction.reportIssue,
  ];
});
