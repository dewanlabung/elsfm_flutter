import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_state.dart';
import '../providers/auth_notifier.dart';
import '../widgets/dev_mode_toggle.dart';
import '../widgets/email_field.dart';
import '../widgets/password_field.dart';
import '../widgets/credential_saver.dart';
import 'google_oauth_screen.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final storage = const FlutterSecureStorage();
    final saver = CredentialSaver(storage);
    final savedEmail = await saver.getSavedEmail();
    if (savedEmail != null && mounted) {
      setState(() {
        emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email and password required')),
      );
      return;
    }

    // Save credentials if "Remember me" is checked
    if (_rememberMe) {
      final storage = const FlutterSecureStorage();
      final saver = CredentialSaver(storage);
      saver.saveEmail(email);
    }

    ref.read(authNotifierProvider.notifier).loginWithEmail(email, password);
  }

  void _handleGoogleLogin() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GoogleOAuthScreen(
        onSuccess: ({String? token}) {
          if (token != null) {
            ref.read(authNotifierProvider.notifier).loginWithSocialToken(token);
          } else {
            ref.read(authNotifierProvider.notifier).loginWithSession();
          }
        },
      ),
    ));
  }

  void _handleForgotPassword() {
    final emailCtrl = TextEditingController(text: emailController.text.trim());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (email.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final msg = await ref
                    .read(authNotifierProvider.notifier)
                    .forgotPassword(email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg)),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.state == AuthState.authenticating;

    return Scaffold(
      appBar: AppBar(title: const Text('ELSFM')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.music_note,
                      size: 80,
                      color: Color(0xFF1DB954),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Welcome to ELSFM',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 32),
                    EmailField(
                      controller: emailController,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),
                    PasswordField(
                      controller: passwordController,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 12),
                    RememberMeCheckbox(
                      initialValue: _rememberMe,
                      onChanged: (value) {
                        setState(() => _rememberMe = value);
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isLoading ? null : _handleForgotPassword,
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFF1DB954),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Login with Email',
                                style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: isLoading ? null : _handleGoogleLogin,
                        icon: const Icon(Icons.login),
                        label: const Text('Sign in with Google'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account?"),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) => const RegisterScreen()),
                                  ),
                          child: const Text('Sign Up'),
                        ),
                      ],
                    ),
                    if (authState.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          authState.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const DevModeToggle(),
        ],
      ),
    );
  }
}
