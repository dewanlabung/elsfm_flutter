import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/biometric_provider.dart';
import '../services/biometric_auth_service.dart';

/// Biometric login button (fingerprint or face unlock)
class BiometricLoginButton extends ConsumerWidget {
  final VoidCallback onSuccess;
  final VoidCallback? onFailure;

  const BiometricLoginButton({
    required this.onSuccess,
    this.onFailure,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biometricSupport = ref.watch(biometricSupportProvider);
    final biometricEnabled = ref.watch(biometricEnabledProvider);

    return biometricSupport.when(
      data: (supported) {
        if (!supported) return const SizedBox.shrink();

        return biometricEnabled.when(
          data: (enabled) {
            if (!enabled) return const SizedBox.shrink();

            return SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _authenticateWithBiometric(context, ref),
                icon: const Icon(Icons.fingerprint),
                label: const Text('Unlock with Biometric'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue[600],
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _authenticateWithBiometric(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final service = ref.read(biometricAuthServiceProvider);
      final token = await service.authenticateWithBiometric();

      if (token != null && context.mounted) {
        // Token retrieved successfully
        onSuccess();
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric authentication failed. Please try again.'),
          ),
        );
        onFailure?.call();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      onFailure?.call();
    }
  }
}
