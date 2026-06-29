import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/models/auth_state.dart';
import '../../../features/auth/providers/auth_notifier.dart';
import '../../../features/auth/providers/biometric_provider.dart';
import '../../../features/settings/providers/theme_provider.dart';
import 'account_settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    if (authState.state != AuthState.authenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Please log in to view your profile')),
      );
    }

    final user = authState.user!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () =>
                ref.read(themeModeProvider.notifier).toggle(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── User info card ─────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundImage: user.avatar != null
                          ? NetworkImage(user.avatar!)
                          : null,
                      child: user.avatar == null
                          ? Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.grey),
                          ),
                          if (user.emailVerified) ...[
                            const SizedBox(height: 8),
                            Chip(
                              label: const Text('Email Verified',
                                  style: TextStyle(fontSize: 12)),
                              backgroundColor: Colors.green.withOpacity(0.15),
                              labelStyle:
                                  const TextStyle(color: Colors.green),
                              side: BorderSide(
                                  color: Colors.green.withOpacity(0.4)),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            Text('Settings', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),

            // ── Account Settings ───────────────────────────────────────────
            ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: const Text('Account Settings'),
              subtitle: const Text('Name, email, password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const AccountSettingsScreen()),
              ),
            ),
            const Divider(height: 1, indent: 56),

            // ── Notifications ──────────────────────────────────────────────
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notifications'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification settings coming soon')),
              ),
            ),
            const Divider(height: 1, indent: 56),

            // ── Theme ──────────────────────────────────────────────────────
            SwitchListTile(
              secondary:
                  Icon(isDark ? Icons.dark_mode : Icons.light_mode),
              title: Text(isDark ? 'Dark Mode' : 'Light Mode'),
              subtitle: Text(isDark ? 'Tap to switch to light' : 'Tap to switch to dark'),
              value: isDark,
              onChanged: (_) =>
                  ref.read(themeModeProvider.notifier).toggle(),
            ),
            const Divider(height: 1, indent: 56),

            // ── Biometric ──────────────────────────────────────────────────
            const _BiometricTile(),

            const SizedBox(height: 24),

            // ── Log Out ────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Log Out',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.red),
                ),
                onPressed: () async {
                  await ref.read(authNotifierProvider.notifier).logout();
                  if (context.mounted) context.go('/home');
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Biometric tile ─────────────────────────────────────────────────────────────

class _BiometricTile extends ConsumerWidget {
  const _BiometricTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canUseAsync = ref.watch(biometricSupportProvider);
    return canUseAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (canUse) {
        if (!canUse) return const SizedBox.shrink();
        return ref.watch(biometricEnabledProvider).when(
          loading: () => const ListTile(
            leading: Icon(Icons.fingerprint),
            title: Text('Biometric Login'),
            trailing: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (isEnabled) => SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: const Text('Biometric Login'),
            subtitle: Text(
              isEnabled ? 'Enabled' : 'Disabled',
              style: TextStyle(
                  color: isEnabled ? Colors.green : Colors.grey),
            ),
            value: isEnabled,
            onChanged: (value) async {
              if (value) {
                await ref
                    .read(authNotifierProvider.notifier)
                    .enableBiometricLogin();
              } else {
                await ref
                    .read(authNotifierProvider.notifier)
                    .disableBiometricLogin();
              }
              ref.invalidate(biometricEnabledProvider);
            },
          ),
        );
      },
    );
  }
}
