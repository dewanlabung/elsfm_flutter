# API Client Setup

Dio HTTP client with interceptors, error handling, and authentication.

## Basic Setup

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiClient {
  final Dio dio;

  ApiClient(this.dio);

  // Endpoints...
  Future<BackendResponse<List<Track>>> getTracks({
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/tracks',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return _parseResponse(response.data!, (data) => Track.fromJson(data));
  }
}
```

## Dio Provider with Interceptors

```dart
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Add interceptors
  dio.interceptors.addAll([
    AuthInterceptor(ref),
    ErrorInterceptor(),
    LoggingInterceptor(),
  ]);

  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.read(dioProvider));
});
```

## Auth Interceptor

Automatically attach authorization token to all requests.

```dart
class AuthInterceptor extends Interceptor {
  final Ref ref;

  AuthInterceptor(this.ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await ref.read(authServiceProvider).getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // If 401, refresh token and retry
    if (err.response?.statusCode == 401) {
      try {
        await ref.read(authServiceProvider).refreshToken();
        // Retry original request
        return handler.resolve(await _retry(err.requestOptions));
      } catch (e) {
        // Refresh failed, redirect to login
        ref.read(authNotifierProvider.notifier).logout();
      }
    }
    handler.next(err);
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    return ref.read(dioProvider).request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}
```

## Error Interceptor

Convert HTTP errors to structured exceptions.

```dart
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;

    if (response?.statusCode == 401) {
      handler.reject(DioException(
        requestOptions: err.requestOptions,
        error: UnauthorizedException('Unauthorized access'),
      ));
    } else if (response?.statusCode == 403) {
      handler.reject(DioException(
        requestOptions: err.requestOptions,
        error: ForbiddenException('Access denied'),
      ));
    } else if (response?.statusCode == 404) {
      handler.reject(DioException(
        requestOptions: err.requestOptions,
        error: NotFoundException('Resource not found'),
      ));
    } else if (response?.statusCode == 429) {
      handler.reject(DioException(
        requestOptions: err.requestOptions,
        error: RateLimitException('Too many requests'),
      ));
    } else if (response?.statusCode == 500) {
      handler.reject(DioException(
        requestOptions: err.requestOptions,
        error: ServerException(
          'Server error',
          statusCode: response?.statusCode ?? 0,
        ),
      ));
    } else if (err.type == DioExceptionType.connectionTimeout) {
      handler.reject(DioException(
        requestOptions: err.requestOptions,
        error: NetworkException('Connection timeout'),
      ));
    } else if (err.type == DioExceptionType.unknown) {
      handler.reject(DioException(
        requestOptions: err.requestOptions,
        error: NetworkException('Network error: ${err.message}'),
      ));
    } else {
      handler.next(err);
    }
  }
}
```

## Logging Interceptor

Log requests and responses for debugging.

```dart
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('→ ${options.method} ${options.uri}');
    debugPrint('  Headers: ${options.headers}');
    if (options.data != null) {
      debugPrint('  Data: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('← ${response.statusCode} ${response.requestOptions.uri}');
    debugPrint('  Response: ${response.data}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('✗ ${err.requestOptions.method} ${err.requestOptions.uri}');
    debugPrint('  Error: ${err.message}');
    debugPrint('  Response: ${err.response?.data}');
    handler.next(err);
  }
}
```

## Retry Logic

Automatic retry for transient failures with exponential backoff.

```dart
class RetryInterceptor extends Interceptor {
  static const maxRetries = 3;
  static const retryDelay = Duration(milliseconds: 100);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final isTransient = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.unknown ||
        err.response?.statusCode == 429 ||
        err.response?.statusCode == 503;

    if (isTransient && _shouldRetry(err)) {
      final retryCount = (err.requestOptions.extra['retryCount'] ?? 0) as int;

      if (retryCount < maxRetries) {
        // Exponential backoff: 100ms, 200ms, 400ms
        final delay = retryDelay * (pow(2, retryCount).toInt());
        await Future.delayed(delay);

        // Update retry count and retry
        err.requestOptions.extra['retryCount'] = retryCount + 1;
        try {
          final response = await _retry(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          return handler.next(err);
        }
      }
    }
    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    // Don't retry 4xx errors (except 429 and 503)
    if (err.response != null && err.response!.statusCode != null) {
      final code = err.response!.statusCode!;
      if (code >= 400 && code < 500 && code != 429) {
        return false;
      }
    }
    return true;
  }

  Future<Response<dynamic>> _retry(RequestOptions options) async {
    final dio = Dio();
    final opts = Options(
      method: options.method,
      headers: options.headers,
    );
    return dio.request(
      options.path,
      data: options.data,
      queryParameters: options.queryParameters,
      options: opts,
    );
  }
}
```

## API Client Methods

```dart
class ApiClient {
  // Channels
  Future<BackendResponse<List<Channel>>> getChannels() => ...

  // Artists
  Future<PaginationResponse<Artist>> getArtists({int page = 1}) => ...
  Future<Artist> getArtist(int id) => ...

  // Albums
  Future<PaginationResponse<Album>> getAlbums({int page = 1}) => ...
  Future<Album> getAlbum(int id) => ...

  // Tracks
  Future<Track> getTrack(int id) => ...
  Future<PaginationResponse<Track>> getTracks({int page = 1}) => ...
  Future<void> logTrackPlay(int trackId) => 
      dio.post('/tracks/$trackId/plays');

  // Playlists
  Future<PaginationResponse<Playlist>> getPlaylists({int page = 1}) => ...
  Future<Playlist> getPlaylist(int id) => ...
  Future<Playlist> createPlaylist(String name) => 
      dio.post('/playlists', data: {'name': name});
  Future<void> updatePlaylist(int id, String name) => 
      dio.put('/playlists/$id', data: {'name': name});
  Future<void> deletePlaylist(int id) => dio.delete('/playlists/$id');

  // Search
  Future<SearchResponse> search(String query) => 
      dio.get('/search', queryParameters: {'q': query});

  // Helper
  PaginationResponse<T> _parsePaginationResponse<T>(
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final items = (data['data'] as List)
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginationResponse(
      data: items,
      pagination: data['pagination'] != null
          ? PaginationMeta.fromJson(data['pagination'])
          : null,
    );
  }
}
```

## Configuration

```dart
class AppConfig {
  static const String apiBaseUrl = 'https://www.elsfm.com/api/v1';
  static const int requestTimeoutSeconds = 30;
  static const int maxRetries = 3;

  // Feature flags
  static bool get debugLogging => !kReleaseMode;
  static bool get enableRetry => true;
  static bool get enableCaching => true;
}
```
