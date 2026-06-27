import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';
import '../models/backend_response.dart';
import '../models/track.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/playlist.dart';
import '../models/channel.dart';
import '../models/genre.dart';
import '../models/user.dart';

part 'api_client.g.dart';

@RestApi(baseUrl: 'https://www.elsfm.com/api/v1')
abstract class ApiClient {
  factory ApiClient(Dio dio, {String baseUrl}) = _ApiClient;

  // Channels
  @GET('/channel')
  Future<BackendResponse<List<Channel>>> getChannels();

  @GET('/channel/{id}')
  Future<BackendResponse<Map<String, dynamic>>> getChannel(@Path('id') int id);

  // Artists
  @GET('/artists')
  Future<PaginationResponse<Artist>> getArtists({
    @Query('page') int page = 1,
    @Query('per_page') int perPage = 20,
  });

  @GET('/artists/{id}')
  Future<Map<String, dynamic>> getArtist(
    @Path('id') int id, {
    @Query('loader') String loader = 'artist',
  });

  @GET('/artists/{id}/tracks')
  Future<PaginationResponse<Track>> getArtistTracks(
    @Path('id') int id, {
    @Query('page') int page = 1,
    @Query('per_page') int perPage = 20,
  });

  @GET('/artists/{id}/albums')
  Future<PaginationResponse<Album>> getArtistAlbums(
    @Path('id') int id, {
    @Query('page') int page = 1,
    @Query('per_page') int perPage = 20,
  });

  // Albums
  @GET('/albums')
  Future<PaginationResponse<Album>> getAlbums({
    @Query('page') int page = 1,
    @Query('per_page') int perPage = 20,
  });

  @GET('/albums/{id}')
  Future<Map<String, dynamic>> getAlbum(@Path('id') int id);

  // Tracks
  @GET('/tracks/{id}')
  Future<Track> getTrack(@Path('id') int id);

  // Playlists
  @GET('/playlists')
  Future<PaginationResponse<Playlist>> getPlaylists({
    @Query('page') int page = 1,
    @Query('per_page') int perPage = 20,
  });

  @GET('/playlists/{id}')
  Future<Map<String, dynamic>> getPlaylist(@Path('id') int id);

  // Search
  @GET('/search')
  Future<Map<String, dynamic>> search({
    @Query('q') required String query,
    @Query('type') String type = 'track,artist,album,playlist',
    @Query('limit') int limit = 20,
  });

  // User
  @GET('/user')
  Future<User> getCurrentUser();

  @GET('/users/{id}/liked-tracks')
  Future<PaginationResponse<Track>> getLikedTracks(
    @Path('id') int userId, {
    @Query('page') int page = 1,
    @Query('per_page') int perPage = 20,
  });

  @GET('/users/{id}/liked-albums')
  Future<PaginationResponse<Album>> getLikedAlbums(
    @Path('id') int userId, {
    @Query('page') int page = 1,
    @Query('per_page') int perPage = 20,
  });

  @GET('/users/{id}/playlists')
  Future<PaginationResponse<Playlist>> getUserPlaylists(
    @Path('id') int userId, {
    @Query('page') int page = 1,
    @Query('per_page') int perPage = 20,
  });

  // Genres
  @GET('/genres')
  Future<List<Genre>> getGenres();
}
