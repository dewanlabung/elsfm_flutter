import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/models/auth_state.dart';
import '../../../features/auth/providers/auth_notifier.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    if (authState.state != AuthState.authenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(
          child: Text('Please log in to view your profile'),
        ),
      );
    }

    final user = authState.user;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (user?.avatar != null)
                      Center(
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(user!.avatar!),
                        ),
                      ),
                    if (user?.avatar != null) const SizedBox(height: 16),
                    Text(
                      user?.name ?? 'Unknown',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?.email ?? 'No email',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (user?.emailVerified == true) ...[
                      const SizedBox(height: 8),
                      Chip(
                        label: const Text('Email Verified'),
                        backgroundColor:
                            Colors.green.withOpacity(0.2),
                        labelStyle: const TextStyle(color: Colors.green),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Settings section
            Text(
              'Settings',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Account Settings'),
              onTap: () {
                // TODO: Navigate to account settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              onTap: () {
                // TODO: Navigate to notification settings
              },
            ),
            const SizedBox(height: 24),
            // Logout button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Log Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  ref.read(authNotifierProvider.notifier).logout();
                  // Navigate back to login
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
