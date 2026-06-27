import 'package:elsfm/data/repositories/quality_repository.dart';
import 'package:elsfm/data/models/quality_option.dart';

/// Audio quality service
class QualityService {
  final QualityRepository repository;

  QualityService({required this.repository});

  Future<List<QualityOption>> getAvailableQualities() async {
    try {
      return await repository.getAvailableQualities();
    } catch (e) {
      throw QualityException('Failed to load qualities: $e');
    }
  }

  Future<QualityOption?> getPreferredQuality() async {
    try {
      return await repository.getPreferredQuality();
    } catch (e) {
      throw QualityException('Failed to load preferred quality: $e');
    }
  }

  Future<QualityOption> setPreferredQuality(String qualityId) async {
    try {
      return await repository.setPreferredQuality(qualityId: qualityId);
    } catch (e) {
      throw QualityException('Failed to set quality: $e');
    }
  }

  Future<QualityOption> getRecommendedQuality({
    bool isWifi = true,
    int? bandwidthMbps,
  }) async {
    try {
      return await repository.getRecommendedQuality(
        isWifi: isWifi,
        bandwidthMbps: bandwidthMbps,
      );
    } catch (e) {
      throw QualityException('Failed to get recommended quality: $e');
    }
  }
}

class QualityException implements Exception {
  final String message;
  QualityException(this.message);

  @override
  String toString() => 'QualityException: $message';
}
