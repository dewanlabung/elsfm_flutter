import 'package:dio/dio.dart';
import '../models/quality_option.dart';

/// Repository for audio quality preferences
class QualityRepository {
  final Dio dio;

  QualityRepository({required this.dio});

  /// Get all available audio quality options
  /// Authorization: None (public)
  Future<List<QualityOption>> getAvailableQualities() async {
    try {
      final response = await dio.get('/api/v1/audio/quality');

      return ((response.data as List?) ?? [])
          .map((e) => QualityOption.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      rethrow;
    }
  }

  /// Get user's preferred audio quality
  /// Authorization: User must be authenticated
  Future<QualityOption?> getPreferredQuality() async {
    try {
      final response = await dio.get('/api/v1/audio/quality/preferred');

      if (response.data != null) {
        return QualityOption.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } on DioException {
      rethrow;
    }
  }

  /// Set user's preferred audio quality
  /// Authorization: User must be authenticated
  Future<QualityOption> setPreferredQuality({
    required String qualityId,
  }) async {
    try {
      final response = await dio.post(
        '/api/v1/audio/quality/preferred',
        data: {
          'quality_id': qualityId,
        },
      );

      return QualityOption.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  /// Get recommended quality based on device and network
  /// Authorization: User must be authenticated
  Future<QualityOption> getRecommendedQuality({
    bool isWifi = true,
    int? bandwidthMbps,
  }) async {
    try {
      final params = <String, dynamic>{
        'is_wifi': isWifi,
        if (bandwidthMbps != null) 'bandwidth_mbps': bandwidthMbps,
      };

      final response = await dio.get(
        '/api/v1/audio/quality/recommended',
        queryParameters: params,
      );

      return QualityOption.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  /// Get quality-specific information (bitrate, file size, etc.)
  /// Authorization: None (public)
  Future<Map<String, dynamic>> getQualityInfo({
    required String qualityId,
  }) async {
    try {
      final response = await dio.get(
        '/api/v1/audio/quality/$qualityId/info',
      );

      return response.data as Map<String, dynamic>;
    } on DioException {
      rethrow;
    }
  }

  /// Check if quality is available in user's subscription
  /// Authorization: User must be authenticated
  Future<bool> isQualityAvailable({
    required String qualityId,
  }) async {
    try {
      final response = await dio.get(
        '/api/v1/audio/quality/$qualityId/available',
      );

      return response.data?['available'] as bool? ?? false;
    } on DioException {
      rethrow;
    }
  }

  /// Get quality statistics for user's account
  /// Authorization: User must be authenticated
  Future<Map<String, dynamic>> getQualityStatistics() async {
    try {
      final response = await dio.get(
        '/api/v1/audio/quality/statistics',
      );

      return response.data as Map<String, dynamic>;
    } on DioException {
      rethrow;
    }
  }
}
