import 'package:dio/dio.dart';

/// Typed error boundary for all app errors.
///
/// Map [DioException] at the [ApiClient] boundary instead of letting raw
/// exceptions propagate into the UI layer.
sealed class AppError implements Exception {
  const AppError();

  /// A human-readable message safe to show in the UI.
  String get message;

  @override
  String toString() => 'AppError(${runtimeType}): $message';
}

/// Network connectivity or timeout failure.
final class NetworkError extends AppError {
  @override
  final String message;
  final Object? cause;

  const NetworkError({
    this.message = 'No internet connection. Please try again.',
    this.cause,
  });
}

/// 401 Unauthorized — token missing or expired.
final class AuthError extends AppError {
  @override
  final String message;

  const AuthError({this.message = 'Session expired. Please sign in again.'});
}

/// 404 Not Found.
final class NotFoundError extends AppError {
  @override
  final String message;

  const NotFoundError({this.message = 'The requested resource was not found.'});
}

/// User-supplied data failed validation (4xx that is not 401/404).
final class ValidationError extends AppError {
  @override
  final String message;
  final Map<String, List<String>>? fieldErrors;

  const ValidationError({
    required this.message,
    this.fieldErrors,
  });
}

/// Any other unexpected error.
final class UnknownError extends AppError {
  @override
  final String message;
  final Object? cause;

  const UnknownError({
    this.message = 'An unexpected error occurred. Please try again.',
    this.cause,
  });
}

/// Map a [DioException] (or any [Object]) to a typed [AppError].
///
/// Call this at the [ApiClient] boundary so all providers only ever see
/// [AppError] subtypes — never raw [DioException].
AppError mapToAppError(Object error) {
  if (error is AppError) return error;

  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkError(
          message: 'Request timed out. Please check your connection.',
          cause: error,
        );
      case DioExceptionType.connectionError:
        return NetworkError(cause: error);
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        if (status == 401) {
          return const AuthError();
        }
        if (status == 404) {
          return const NotFoundError();
        }
        if (status != null && status >= 400 && status < 500) {
          final body = error.response?.data;
          String msg = 'Request failed ($status).';
          if (body is Map<String, dynamic>) {
            msg = body['message'] as String? ??
                body['error'] as String? ??
                msg;
          }
          return ValidationError(message: msg);
        }
        return UnknownError(
          message: 'Server error. Please try again later.',
          cause: error,
        );
      case DioExceptionType.cancel:
        return const UnknownError(message: 'Request was cancelled.');
      case DioExceptionType.badCertificate:
        return const UnknownError(message: 'SSL certificate error.');
      case DioExceptionType.unknown:
        return NetworkError(cause: error);
      default:
        return UnknownError(cause: error, message: error.toString());
    }
  }

  return UnknownError(cause: error, message: error.toString());
}
