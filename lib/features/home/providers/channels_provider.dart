// channels_provider.dart is no longer used by the Home screen.
// The Home screen now uses homeDataProvider (home_provider.dart) which fetches
// public playlists, genres, and top tracks from authenticated-free endpoints.
//
// This file is retained to avoid breaking any external references that may
// still import it, but channelsProvider is intentionally unused.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/channel.dart';

// Stub — always returns an empty list and makes no network requests.
final channelsProvider = FutureProvider<List<Channel>>((ref) async {
  return const <Channel>[];
});
