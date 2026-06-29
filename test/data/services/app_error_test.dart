import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elsfm/data/models/app_error.dart';

// ---------------------------------------------------------------------------
// Helper: build a DioException with a mock response.
// ---------------------------------------------------------------------------
DioException _dioError({
  required DioExceptionType type,
  int? statusCode,
  Map<String, dynamic>? responseData,
}) {
  Response<dynamic>? response;
  if (statusCode != null) {
    response = Response(
      requestOptions: RequestOptions(path: '/test'),
      statusCode: statusCode,
      data: responseData,
    );
  }
  return DioException(
    requestOptions: RequestOptions(path: '/test'),
    type: type,
    response: response,
  );
}

void main() {
  group('mapToAppError', () {
    // -------------------------------------------------------------------------
    // Pass-through for already-typed errors
    // -------------------------------------------------------------------------
    test('returns the same AppError when passed an AppError', () {
      const input = AuthError();
      final result = mapToAppError(input);
      expect(result, same(input));
    });

    // -------------------------------------------------------------------------
    // Timeout → NetworkError
    // -------------------------------------------------------------------------
    test('connectionTimeout → NetworkError with timeout message', () {
      final error = _dioError(type: DioExceptionType.connectionTimeout);
      final result = mapToAppError(error);

      expect(result, isA<NetworkError>());
      expect(result.message, contains('timed out'));
    });

    test('sendTimeout → NetworkError with timeout message', () {
      final error = _dioError(type: DioExceptionType.sendTimeout);
      final result = mapToAppError(error);

      expect(result, isA<NetworkError>());
      expect(result.message, contains('timed out'));
    });

    test('receiveTimeout → NetworkError with timeout message', () {
      final error = _dioError(type: DioExceptionType.receiveTimeout);
      final result = mapToAppError(error);

      expect(result, isA<NetworkError>());
      expect(result.message, contains('timed out'));
    });

    // -------------------------------------------------------------------------
    // Connection error → NetworkError
    // -------------------------------------------------------------------------
    test('connectionError → NetworkError with default message', () {
      final error = _dioError(type: DioExceptionType.connectionError);
      final result = mapToAppError(error);

      expect(result, isA<NetworkError>());
    });

    test('unknown DioExceptionType → NetworkError', () {
      final error = _dioError(type: DioExceptionType.unknown);
      final result = mapToAppError(error);

      expect(result, isA<NetworkError>());
    });

    // -------------------------------------------------------------------------
    // HTTP 401 → AuthError
    // -------------------------------------------------------------------------
    test('HTTP 401 → AuthError', () {
      final error = _dioError(
        type: DioExceptionType.badResponse,
        statusCode: 401,
      );
      final result = mapToAppError(error);

      expect(result, isA<AuthError>());
      expect(result.message, contains('sign in'));
    });

    // -------------------------------------------------------------------------
    // HTTP 403 → ValidationError (not 401 / 404)
    // -------------------------------------------------------------------------
    test('HTTP 403 → ValidationError', () {
      final error = _dioError(
        type: DioExceptionType.badResponse,
        statusCode: 403,
        responseData: {'message': 'Forbidden'},
      );
      final result = mapToAppError(error);

      expect(result, isA<ValidationError>());
      expect(result.message, contains('Forbidden'));
    });

    // -------------------------------------------------------------------------
    // HTTP 404 → NotFoundError
    // -------------------------------------------------------------------------
    test('HTTP 404 → NotFoundError', () {
      final error = _dioError(
        type: DioExceptionType.badResponse,
        statusCode: 404,
      );
      final result = mapToAppError(error);

      expect(result, isA<NotFoundError>());
    });

    // -------------------------------------------------------------------------
    // HTTP 422 → ValidationError with message from body
    // -------------------------------------------------------------------------
    test('HTTP 422 → ValidationError with message from response body', () {
      final error = _dioError(
        type: DioExceptionType.badResponse,
        statusCode: 422,
        responseData: {'message': 'The given data was invalid.'},
      );
      final result = mapToAppError(error);

      expect(result, isA<ValidationError>());
      expect(
        (result as ValidationError).message,
        'The given data was invalid.',
      );
    });

    test('HTTP 422 falls back to error field when message absent', () {
      final error = _dioError(
        type: DioExceptionType.badResponse,
        statusCode: 422,
        responseData: {'error': 'Validation failed'},
      );
      final result = mapToAppError(error);

      expect(result, isA<ValidationError>());
      expect((result as ValidationError).message, 'Validation failed');
    });

    test('HTTP 422 with no body uses generic message', () {
      final error = _dioError(
        type: DioExceptionType.badResponse,
        statusCode: 422,
      );
      final result = mapToAppError(error);

      expect(result, isA<ValidationError>());
      expect(result.message, contains('422'));
    });

    // -------------------------------------------------------------------------
    // HTTP 5xx → UnknownError (server error)
    // -------------------------------------------------------------------------
    test('HTTP 500 → UnknownError with server error message', () {
      final error = _dioError(
        type: DioExceptionType.badResponse,
        statusCode: 500,
      );
      final result = mapToAppError(error);

      expect(result, isA<UnknownError>());
      expect(result.message, contains('Server error'));
    });

    test('HTTP 503 → UnknownError', () {
      final error = _dioError(
        type: DioExceptionType.badResponse,
        statusCode: 503,
      );
      final result = mapToAppError(error);

      expect(result, isA<UnknownError>());
    });

    // -------------------------------------------------------------------------
    // Cancel → UnknownError
    // -------------------------------------------------------------------------
    test('cancel → UnknownError with cancelled message', () {
      final error = _dioError(type: DioExceptionType.cancel);
      final result = mapToAppError(error);

      expect(result, isA<UnknownError>());
      expect(result.message, contains('cancelled'));
    });

    // -------------------------------------------------------------------------
    // Bad certificate → UnknownError
    // -------------------------------------------------------------------------
    test('badCertificate → UnknownError with SSL message', () {
      final error = _dioError(type: DioExceptionType.badCertificate);
      final result = mapToAppError(error);

      expect(result, isA<UnknownError>());
      expect(result.message, contains('SSL'));
    });

    // -------------------------------------------------------------------------
    // Non-Dio exception → UnknownError
    // -------------------------------------------------------------------------
    test('non-DioException → UnknownError', () {
      final result = mapToAppError(Exception('Something broke'));

      expect(result, isA<UnknownError>());
    });

    test('string error → UnknownError', () {
      final result = mapToAppError('plain string error');
      expect(result, isA<UnknownError>());
    });
  });

  // ---------------------------------------------------------------------------
  // AppError subtypes – basic properties
  // ---------------------------------------------------------------------------
  group('AppError subtypes', () {
    test('NetworkError has sensible default message', () {
      const err = NetworkError();
      expect(err.message, isNotEmpty);
      expect(err.toString(), contains('NetworkError'));
    });

    test('AuthError has sensible default message', () {
      const err = AuthError();
      expect(err.message, isNotEmpty);
    });

    test('NotFoundError has sensible default message', () {
      const err = NotFoundError();
      expect(err.message, isNotEmpty);
    });

    test('ValidationError stores fieldErrors', () {
      const err = ValidationError(
        message: 'Invalid input',
        fieldErrors: {
          'email': ['Email is required'],
          'name': ['Name too short'],
        },
      );

      expect(err.fieldErrors?['email']?.first, 'Email is required');
      expect(err.fieldErrors?['name']?.first, 'Name too short');
    });

    test('UnknownError stores cause', () {
      final cause = Exception('root cause');
      final err = UnknownError(cause: cause);
      expect(err.cause, same(cause));
    });
  });
}
