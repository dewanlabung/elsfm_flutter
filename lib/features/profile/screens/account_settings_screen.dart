import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_notifier.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _savingProfile = false;
  bool _savingPassword = false;
  bool _obscureCurrentPass = true;
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    if (name.isEmpty || email.isEmpty) {
      _showSnack('Name and email cannot be empty');
      return;
    }
    setState(() => _savingProfile = true);
    try {
      await ref.read(authNotifierProvider.notifier).updateProfile(
            name: name,
            email: email,
          );
      if (mounted) _showSnack('Profile updated successfully');
    } catch (e) {
      if (mounted) _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    final current = _currentPassCtrl.text;
    final newPass = _newPassCtrl.text;
    final confirm = _confirmPassCtrl.text;

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      _showSnack('All password fields are required');
      return;
    }
    if (newPass != confirm) {
      _showSnack('New passwords do not match');
      return;
    }
    if (newPass.length < 8) {
      _showSnack('Password must be at least 8 characters');
      return;
    }

    setState(() => _savingPassword = true);
    try {
      await ref.read(authNotifierProvider.notifier).changePassword(
            currentPassword: current,
            newPassword: newPass,
            confirmation: confirm,
          );
      if (mounted) {
        _currentPassCtrl.clear();
        _newPassCtrl.clear();
        _confirmPassCtrl.clear();
        _showSnack('Password changed successfully');
      }
    } catch (e) {
      if (mounted) _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile info ───────────────────────────────────────────────
            Text('Profile Information',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              enabled: !_savingProfile,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              enabled: !_savingProfile,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _savingProfile ? null : _saveProfile,
                child: _savingProfile
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Profile'),
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // ── Change password ────────────────────────────────────────────
            Text('Change Password',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _PassField(
              controller: _currentPassCtrl,
              label: 'Current Password',
              obscure: _obscureCurrentPass,
              enabled: !_savingPassword,
              onToggle: () =>
                  setState(() => _obscureCurrentPass = !_obscureCurrentPass),
              action: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            _PassField(
              controller: _newPassCtrl,
              label: 'New Password',
              obscure: _obscureNewPass,
              enabled: !_savingPassword,
              onToggle: () =>
                  setState(() => _obscureNewPass = !_obscureNewPass),
              action: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            _PassField(
              controller: _confirmPassCtrl,
              label: 'Confirm New Password',
              obscure: _obscureConfirmPass,
              enabled: !_savingPassword,
              onToggle: () =>
                  setState(() => _obscureConfirmPass = !_obscureConfirmPass),
              action: TextInputAction.done,
              onSubmitted: (_) => _changePassword(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _savingPassword ? null : _changePassword,
                child: _savingPassword
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Change Password'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _PassField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final bool enabled;
  final VoidCallback onToggle;
  final TextInputAction action;
  final ValueChanged<String>? onSubmitted;

  const _PassField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.enabled,
    required this.onToggle,
    required this.action,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscure,
      textInputAction: action,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
