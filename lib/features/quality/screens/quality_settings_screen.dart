import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/quality_provider.dart';

/// Audio quality settings screen
class QualitySettingsScreen extends ConsumerWidget {
  const QualitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableAsync = ref.watch(availableQualitiesProvider);
    final preferredAsync = ref.watch(preferredQualityProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Audio Quality')),
      body: availableAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (qualities) => preferredAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
          data: (preferred) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Select audio quality',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ...qualities.map((quality) {
                final isSelected = preferred?.id == quality.id;
                return Card(
                  child: ListTile(
                    leading: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.circle_outlined),
                    title: Text(quality.label),
                    subtitle: Text('${quality.bitrate} kbps - ${quality.format}'),
                    onTap: () async {
                      await ref
                          .read(qualitySelectionProvider.notifier)
                          .setQuality(quality.id);
                    },
                  ),
                );
              }),
              const SizedBox(height: 24),
              const Text(
                'Higher quality uses more data',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
