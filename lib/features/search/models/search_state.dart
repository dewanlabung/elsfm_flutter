import 'package:elsfm/data/models/track.dart';
import 'package:elsfm/data/models/artist.dart';
import 'package:elsfm/data/models/album.dart';
import 'package:elsfm/data/models/playlist.dart';

/// Search state container for UI updates
class SearchState {
  final String query;
  final SearchResults? results;
  final TrendingResults? trending;
  final bool isLoading;
  final String? error;

  SearchState({
    required this.query,
    this.results,
    this.trending,
    required this.isLoading,
    this.error,
  });

  factory SearchState.initial() => SearchState(
    query: '',
    results: null,
    trending: null,
    isLoading: false,
    error: null,
  );

  bool get hasResults => results?.isNotEmpty ?? false;

  bool get hasTrending => trending?.isNotEmpty ?? false;

  bool get isEmpty => !hasResults && !hasTrending && query.isEmpty;

  SearchState copyWith({
    String? query,
    SearchResults? results,
    TrendingResults? trending,
    bool? isLoading,
    String? error,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      trending: trending ?? this.trending,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Search results container
class SearchResults {
  final List<Track> songs;
  final List<Artist> artists;
  final List<Album> albums;
  final List<Playlist> playlists;
  final int page;
  final int total;
  final String query;

  SearchResults({
    required this.songs,
    required this.artists,
    required this.albums,
    required this.playlists,
    this.page = 1,
    this.total = 0,
    this.query = '',
  });

  factory SearchResults.empty() => SearchResults(
    songs: [],
    artists: [],
    albums: [],
    playlists: [],
  );

  bool get isEmpty => songs.isEmpty && artists.isEmpty && albums.isEmpty && playlists.isEmpty;

  bool get isNotEmpty => !isEmpty;
}

/// Trending results container
class TrendingResults {
  final List<Track> songs;
  final List<Artist> artists;
  final String type;
  final String period;

  TrendingResults({
    required this.songs,
    required this.artists,
    required this.type,
    required this.period,
  });

  bool get isEmpty => songs.isEmpty && artists.isEmpty;

  bool get isNotEmpty => !isEmpty;
}
