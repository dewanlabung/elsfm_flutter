# Profile Screen

User profile with avatar, account info, settings tiles, biometric toggle, and
sign-out. Mirrors `lib/features/profile/screens/profile_screen.dart` and
`lib/features/settings/screens/settings_screen.dart`.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:elsfm/features/auth/models/auth_state.dart';
import 'package:elsfm/features/auth/providers/auth_notifier.dart';
import 'package:elsfm/features/auth/providers/biometric_provider.dart';
import 'package:elsfm/data/models/user.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    if (authState.state == AuthState.authenticating) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authState.state != AuthState.authenticated) {
      return _UnauthenticatedView(
        errorMessage: authState.errorMessage,
      );
    }

    return _ProfileBody(user: authState.user!);
  }
}

// ---------------------------------------------------------------------------
// Unauthenticated view
// ---------------------------------------------------------------------------

class _UnauthenticatedView extends StatelessWidget {
  final String? errorMessage;

  const _UnauthenticatedView({this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Log in to view your profile',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.push('/login'),
                child: const Text('Log In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Authenticated body
// ---------------------------------------------------------------------------

class _ProfileBody extends ConsumerWidget {
  final User user;

  const _ProfileBody({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar + name card ───────────────────────────────────────
            _UserCard(user: user),
            const SizedBox(height: 24),

            // ── Favourites shortcut ──────────────────────────────────────
            Text('Library', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _ProfileTile(
              icon: Icons.favorite_border,
              iconColor: Colors.red,
              title: 'Liked Songs',
              subtitle: 'Tracks you have hearted',
              onTap: () => context.push('/library'),
            ),
            _ProfileTile(
              icon: Icons.playlist_play,
              iconColor: Colors.blue,
              title: 'Your Playlists',
              subtitle: 'Playlists you created',
              onTap: () => context.push('/library'),
            ),
            const SizedBox(height: 24),

            // ── Account ──────────────────────────────────────────────────
            Text('Account', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _ProfileTile(
              icon: Icons.email_outlined,
              iconColor: Colors.teal,
              title: 'Email',
              subtitle: user.email,
              trailing: user.emailVerified
                  ? const _VerifiedBadge()
                  : null,
              onTap: null, // read-only
            ),
            _ProfileTile(
              icon: Icons.lock_outline,
              iconColor: Colors.orange,
              title: 'Change Password',
              subtitle: 'Update your account password',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon')),
              ),
            ),
            const SizedBox(height: 8),

            // ── Biometric toggle (renders only when hardware is present) ──
            const _BiometricTile(),
            const SizedBox(height: 24),

            // ── Sign out ─────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _confirmSignOut(context, ref),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need to log in again to access your library.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authNotifierProvider.notifier).logout();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// User card
// ---------------------------------------------------------------------------

class _UserCard extends StatelessWidget {
  final User user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 36,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage:
                  user.avatar != null ? NetworkImage(user.avatar!) : null,
              child: user.avatar == null
                  ? Text(
                      user.name.isNotEmpty
                          ? user.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 28),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            // Name + email
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Biometric tile — only renders when hardware supports it
// ---------------------------------------------------------------------------

class _BiometricTile extends ConsumerStatefulWidget {
  const _BiometricTile();

  @override
  ConsumerState<_BiometricTile> createState() => _BiometricTileState();
}

class _BiometricTileState extends ConsumerState<_BiometricTile> {
  @override
  Widget build(BuildContext context) {
    final canUseBiometrics  = ref.watch(biometricSupportProvider);
    final isBiometricEnabled = ref.watch(biometricEnabledProvider);

    return canUseBiometrics.when(
      loading: () => const SizedBox.shrink(),
      error:   (_, __) => const SizedBox.shrink(),
      data: (canUse) {
        if (!canUse) return const SizedBox.shrink();

        return isBiometricEnabled.when(
          loading: () => ListTile(
            leading: const Icon(Icons.fingerprint),
            title: const Text('Biometric Login'),
            enabled: false,
            trailing: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (isEnabled) => SwitchListTile(
            secondary: Icon(
              Icons.fingerprint,
              color: isEnabled
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            title: const Text('Biometric Login'),
            subtitle: Text(
              isEnabled ? 'Enabled' : 'Disabled',
              style: TextStyle(
                color: isEnabled ? Colors.green : Colors.grey,
              ),
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

// ---------------------------------------------------------------------------
// Reusable profile tile
// ---------------------------------------------------------------------------

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ProfileTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
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
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: Colors.grey),
      ),
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, size: 20, color: Colors.grey)
              : null),
      onTap: onTap,
    );
  }
}

// ---------------------------------------------------------------------------
// Verified badge chip
// ---------------------------------------------------------------------------

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: const Text('Verified', style: TextStyle(fontSize: 11)),
      backgroundColor: Colors.green.withOpacity(0.15),
      labelStyle: const TextStyle(color: Colors.green),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      avatar: const Icon(Icons.verified, size: 14, color: Colors.green),
    );
  }
}
```

## Providers Referenced

| Provider | File | Returns |
|----------|------|---------|
| `authNotifierProvider` | `features/auth/providers/auth_notifier.dart` | `AuthStateData` |
| `biometricSupportProvider` | `features/auth/providers/biometric_provider.dart` | `AsyncValue<bool>` |
| `biometricEnabledProvider` | `features/auth/providers/biometric_provider.dart` | `AsyncValue<bool>` |

## GoRouter Entry

```dart
GoRoute(
  path: '/profile',
  builder: (context, state) => const ProfileScreen(),
),
```

## AuthState Guards

```dart
// Three states you must handle:
switch (authState.state) {
  case AuthState.authenticating:
    return LoadingSpinner();   // Token being validated on startup
  case AuthState.unauthenticated:
  case AuthState.error:
    return LoginPrompt();      // Show login CTA
  case AuthState.authenticated:
    return ProfileBody(user: authState.user!);
}
```

## Adding a Favourites Count

```dart
// In _UserCard or as a stat row below the avatar:
final favAsync = ref.watch(favoritesProvider);
final count = favAsync.valueOrNull?.length ?? 0;

Text('$count liked songs', style: theme.textTheme.bodySmall);
```
