import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/track.dart';
import '../../../data/models/album.dart';
import '../../../data/models/playlist.dart';
import '../../../data/providers/api_client_provider.dart';
import '../../auth/providers/auth_notifier.dart';
import '../../auth/models/auth_state.dart';

final likedTracksProvider = FutureProvider<List<Track>>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  if (authState.state != AuthState.authenticated || authState.user == null) {
    return [];
  }

  final apiClient = ref.watch(apiClientProvider);
  try {
    final response = await apiClient.getLikedTracks(authState.user!.id);
    return response.data;
  } catch (e) {
    throw Exception('Failed to fetch liked tracks: $e');
  }
});

final likedAlbumsProvider = FutureProvider<List<Album>>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  if (authState.state != AuthState.authenticated || authState.user == null) {
    return [];
  }

  final apiClient = ref.watch(apiClientProvider);
  try {
    final response = await apiClient.getLikedAlbums(authState.user!.id);
    return response.data;
  } catch (e) {
    throw Exception('Failed to fetch liked albums: $e');
  }
});

final userPlaylistsProvider = FutureProvider<List<Playlist>>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  if (authState.state != AuthState.authenticated || authState.user == null) {
    return [];
  }

  final apiClient = ref.watch(apiClientProvider);
  try {
    final response = await apiClient.getUserPlaylists(authState.user!.id);
    return response.data;
  } catch (e) {
    throw Exception('Failed to fetch user playlists: $e');
  }
});
