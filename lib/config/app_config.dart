class AppConfig {
  static const String apiBaseUrl = 'https://www.elsfm.com/api/v1';
  static const String webBaseUrl = 'https://www.elsfm.com';
  static const String appId = 'com.elsfm.app';
  static const int maxConcurrentDownloads = 3;
  static const int requestTimeoutSeconds = 30;

  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');
  static String get logLevel => isProduction ? 'error' : 'debug';
}
