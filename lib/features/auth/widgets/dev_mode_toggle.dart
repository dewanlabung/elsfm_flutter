import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dev_auth_provider.dart';

/// Dev-only widget to toggle auto-login during testing
class DevModeToggle extends ConsumerStatefulWidget {
  const DevModeToggle({super.key});

  @override
  ConsumerState<DevModeToggle> createState() => _DevModeToggleState();
}

class _DevModeToggleState extends ConsumerState<DevModeToggle> {
  bool _isEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkDevMode();
  }

  Future<void> _checkDevMode() async {
    final devAuth = ref.read(devAuthHelperProvider);
    final isEnabled = await devAuth.isDevModeEnabled();
    setState(() => _isEnabled = isEnabled);
  }

  Future<void> _toggleDevMode() async {
    setState(() => _isLoading = true);
    try {
      final devAuth = ref.read(devAuthHelperProvider);
      if (_isEnabled) {
        await devAuth.disableDevMode();
      } else {
        await devAuth.enableDevMode();
      }
      setState(() => _isEnabled = !_isEnabled);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEnabled ? '✓ Dev mode ON - auto-login enabled' : '✗ Dev mode OFF',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _isEnabled ? Colors.green[50] : Colors.grey[100],
        border: Border(
          top: BorderSide(
            color: _isEnabled ? Colors.green : Colors.grey[300]!,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isEnabled ? Icons.check_circle : Icons.construction,
            color: _isEnabled ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Dev Mode',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _isEnabled
                      ? 'Auto-login: ${DevAuthHelperConstants.testEmail}'
                      : 'Tap to enable quick test login',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isEnabled,
            onChanged: _isLoading ? null : (_) => _toggleDevMode(),
          ),
        ],
      ),
    );
  }
}

class DevAuthHelperConstants {
  static const testEmail = 'live.elsfm@gmail.com';
}
