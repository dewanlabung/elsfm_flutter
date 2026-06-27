import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elsfm/data/providers/http_client_provider.dart';
import 'package:elsfm/data/repositories/quality_repository.dart';
import '../services/quality_service.dart';
import 'package:elsfm/data/models/quality_option.dart';

/// Quality repository provider
final qualityRepositoryProvider = Provider<QualityRepository>((ref) {
  final dio = ref.watch(httpClientProvider);
  return QualityRepository(dio: dio);
});

/// Quality service provider
final qualityServiceProvider = Provider<QualityService>((ref) {
  final repository = ref.watch(qualityRepositoryProvider);
  return QualityService(repository: repository);
});

/// Available qualities provider
final availableQualitiesProvider = FutureProvider<List<QualityOption>>((ref) async {
  final service = ref.watch(qualityServiceProvider);
  return await service.getAvailableQualities();
});

/// Preferred quality provider
final preferredQualityProvider = FutureProvider<QualityOption?>((ref) async {
  final service = ref.watch(qualityServiceProvider);
  return await service.getPreferredQuality();
});

/// Quality selection notifier
class QualitySelectionNotifier extends AsyncNotifier<QualityOption?> {
  @override
  Future<QualityOption?> build() async {
    final service = ref.read(qualityServiceProvider);
    return await service.getPreferredQuality();
  }

  Future<void> setQuality(String qualityId) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(qualityServiceProvider);
      final quality = await service.setPreferredQuality(qualityId);
      state = AsyncValue.data(quality);
      ref.invalidate(preferredQualityProvider);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

/// Quality selection provider
final qualitySelectionProvider = AsyncNotifierProvider<QualitySelectionNotifier, QualityOption?>(
  () => QualitySelectionNotifier(),
);
