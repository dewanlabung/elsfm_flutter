import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elsfm/features/auth/providers/auth_notifier.dart';
import 'package:elsfm/features/auth/models/auth_state.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: ListView(
        children: [
          // ── Appearance ──────────────────────────────────────────────────
          _SettingsTile(
            icon: Icons.palette_outlined,
            iconColor: Colors.purple,
            title: 'Appearance',
            subtitle: 'Theme, accent and background colors',
            onTap: () => _showComingSoon(context, 'Appearance'),
          ),
          const Divider(height: 1, indent: 72),

          // ── Content Settings ────────────────────────────────────────────
          _SettingsTile(
            icon: Icons.language,
            iconColor: Colors.blue,
            title: 'Content Settings',
            subtitle: 'Language, content region, safe mode',
            onTap: () => _showComingSoon(context, 'Content Settings'),
          ),
          const Divider(height: 1, indent: 72),

          // ── Playback ────────────────────────────────────────────────────
          _SettingsTile(
            icon: Icons.play_circle_outline,
            iconColor: Colors.green,
            title: 'Playback',
            subtitle: 'Equalizer, crossfade, audio quality',
            onTap: () => _showComingSoon(context, 'Playback'),
          ),
          const Divider(height: 1, indent: 72),

          // ── Downloads ───────────────────────────────────────────────────
          _SettingsTile(
            icon: Icons.download_outlined,
            iconColor: Colors.orange,
            title: 'Downloads',
            subtitle: 'Location, auto tagging, auto resume',
            onTap: () => _showComingSoon(context, 'Downloads'),
          ),

          const SizedBox(height: 8),
          const Divider(thickness: 6, color: Colors.transparent),

          // ── Other Settings ──────────────────────────────────────────────
          _SettingsTile(
            icon: Icons.settings_outlined,
            iconColor: Colors.grey,
            title: 'Other Settings',
            subtitle: 'Clear history, reset app',
            onTap: () => _showComingSoon(context, 'Other Settings'),
          ),
          const Divider(height: 1, indent: 72),

          // ── About ───────────────────────────────────────────────────────
          _SettingsTile(
            icon: Icons.info_outline,
            iconColor: Colors.indigo,
            title: 'About',
            subtitle: 'App version, open source licenses',
            onTap: () => _showAboutDialog(context),
          ),

          const SizedBox(height: 8),
          const Divider(thickness: 6, color: Colors.transparent),

          // ── Account ─────────────────────────────────────────────────────
          if (authState.state == AuthState.authenticated) ...[
            _SettingsTile(
              icon: Icons.logout,
              iconColor: Colors.red,
              title: 'Sign Out',
              subtitle: user?.email ?? '',
              titleStyle: const TextStyle(color: Colors.red),
              onTap: () => _confirmSignOut(context, ref),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature settings coming soon')),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'ELSFM',
      applicationVersion: '1.0.0',
      applicationIcon: const FlutterLogo(size: 48),
      children: const [
        Text('ELSFM — Music streaming powered by BeMusic.'),
      ],
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to log in again to access your library.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authNotifierProvider.notifier).logout();
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final TextStyle? titleStyle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.titleStyle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: titleStyle),
      subtitle: Text(
        subtitle,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: Colors.grey),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }
}
