# Error Handling

Structured exception types and retry logic for API reliability.

## Exception Hierarchy

```dart
abstract class AppException implements Exception {
  final String message;
  AppException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException(String message) : super(message);
}

class ServerException extends AppException {
  final int statusCode;
  ServerException(String message, {required this.statusCode})
      : super(message);
}

class UnauthorizedException extends AppException {
  UnauthorizedException(String message) : super(message);
}

class ForbiddenException extends AppException {
  ForbiddenException(String message) : super(message);
}

class NotFoundException extends AppException {
  NotFoundException(String message) : super(message);
}

class RateLimitException extends AppException {
  RateLimitException(String message) : super(message);
}

class ValidationException extends AppException {
  final Map<String, List<String>>? errors;
  ValidationException(String message, {this.errors}) : super(message);
}
```

## Throwing Exceptions

```dart
Future<Track> getTrack(int id) async {
  try {
    final response = await dio.get<Map<String, dynamic>>('/tracks/$id');
    return Track.fromJson(response.data!);
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      throw UnauthorizedException('Unauthorized');
    } else if (e.response?.statusCode == 403) {
      throw ForbiddenException('Access denied');
    } else if (e.response?.statusCode == 404) {
      throw NotFoundException('Track not found');
    } else if (e.response?.statusCode == 429) {
      throw RateLimitException('Too many requests');
    } else if (e.response?.statusCode == 500) {
      throw ServerException(
        'Server error',
        statusCode: e.response?.statusCode ?? 0,
      );
    } else if (e.type == DioExceptionType.connectionTimeout) {
      throw NetworkException('Connection timeout');
    } else {
      throw NetworkException('Failed to load track');
    }
  }
}
```

## Handling in UI

```dart
// In Riverpod provider
final trackProvider = FutureProvider.family<Track, int>((ref, id) async {
  try {
    return await ref.read(trackRepositoryProvider).getTrack(id);
  } on UnauthorizedException {
    // Trigger login flow
    ref.read(authNotifierProvider.notifier).logout();
    return Track.empty();  // Fallback
  } on NetworkException {
    throw NetworkException('No internet connection');
  }
});

// In widget
@override
Widget build(BuildContext context, WidgetRef ref) {
  final trackAsync = ref.watch(trackProvider(trackId));

  return trackAsync.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, stack) {
      String message = 'Unknown error';
      if (error is NetworkException) {
        message = 'No internet connection';
      } else if (error is NotFoundException) {
        message = 'Track not found';
      } else if (error is UnauthorizedException) {
        message = 'Please log in again';
      }
      return Center(child: Text(message));
    },
    data: (track) => Text(track.name),
  );
}
```

## Retry Logic

```dart
Future<T> _retryWithBackoff<T>(
  Future<T> Function() fn, {
  int maxRetries = 3,
  Duration initialDelay = const Duration(milliseconds: 100),
}) async {
  int retries = 0;

  while (true) {
    try {
      return await fn();
    } catch (e) {
      retries++;
      if (retries >= maxRetries) rethrow;

      // Only retry on transient errors
      if (e is! NetworkException && e is! RateLimitException) {
        rethrow;
      }

      // Exponential backoff: 100ms, 200ms, 400ms
      final delay = initialDelay * pow(2, retries - 1).toInt();
      await Future.delayed(delay);
    }
  }
}

// Usage
final tracks = await _retryWithBackoff(
  () => trackRepository.getTracks(page: 1),
  maxRetries: 3,
);
```

## User-Friendly Error Messages

```dart
String getErrorMessage(Exception error) {
  if (error is NetworkException) {
    return 'Network error. Please check your connection and try again.';
  } else if (error is ServerException) {
    return 'Server error. Please try again later.';
  } else if (error is UnauthorizedException) {
    return 'Session expired. Please log in again.';
  } else if (error is NotFoundException) {
    return 'The item you\'re looking for no longer exists.';
  } else if (error is RateLimitException) {
    return 'Too many requests. Please wait a moment and try again.';
  } else if (error is ValidationException) {
    return error.errors?.values.expand((e) => e).join(', ') ?? error.message;
  } else {
    return 'Something went wrong. Please try again.';
  }
}

// Usage in UI
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(getErrorMessage(error)),
    backgroundColor: Colors.red,
  ),
);
```

## Error Logging

```dart
void logError(Exception error, StackTrace stackTrace) {
  if (kDebugMode) {
    debugPrintStack(stackTrace: stackTrace);
    debugPrint('Error: $error');
  }

  // Send to crash reporting in production
  // FirebaseCrashlytics.instance.recordError(error, stackTrace);
}

// Usage
try {
  await someAsyncFunction();
} catch (e, st) {
  logError(e as Exception, st);
  rethrow;
}
```
