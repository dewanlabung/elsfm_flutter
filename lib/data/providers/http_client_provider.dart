import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../config/app_config.dart';

final dioProvider = FutureProvider<Dio>((ref) async {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: Duration(seconds: AppConfig.requestTimeoutSeconds),
      receiveTimeout: Duration(seconds: AppConfig.requestTimeoutSeconds),
      sendTimeout: Duration(seconds: AppConfig.requestTimeoutSeconds),
      contentType: 'application/json',
      validateStatus: (status) => status != null && status < 500,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      },
    ),
  );

  // Add cookie manager for Sanctum session persistence
  final appDocDir = await getApplicationDocumentsDirectory();
  final cookieJar = PersistCookieJar(
    ignoreExpires: false,
    storage: FileStorage('${appDocDir.path}/.cookies/'),
  );
  dio.interceptors.add(CookieManager(cookieJar));

  // Add logging interceptor in debug mode
  if (!AppConfig.isProduction) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ),
    );

    // Add custom auth logging interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = options.headers['Authorization'];
          debugPrint('[API-Auth] ${options.method.toUpperCase()} ${options.path}');
          debugPrint('[API-Auth]   BaseURL: ${options.baseUrl}');
          debugPrint('[API-Auth]   Full URL: ${options.uri}');
          debugPrint('[API-Auth]   Auth Header: ${token != null ? '${(token as String).substring(0, min(20, (token as String).length))}...' : 'NONE'}');
          debugPrint('[API-Auth]   Params: ${options.queryParameters}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('[API-Response] ${response.statusCode} - ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (error, handler) {
          debugPrint('[API-Error] ${error.response?.statusCode} - ${error.requestOptions.path}');
          debugPrint('[API-Error]   Message: ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }

  return dio;
});

/// Sync Dio provider — unwraps [dioProvider] for use in sync Providers.
final httpClientProvider = Provider<Dio>((ref) {
  return ref.watch(dioProvider).when(
    data: (dio) => dio,
    loading: () => throw Exception('Dio not initialised yet'),
    error: (err, _) => throw err,
  );
});
