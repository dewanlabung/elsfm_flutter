import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GoogleOAuthScreen extends StatefulWidget {
  /// Called with the extracted token (or null if not found — falls back to session).
  final void Function({String? token}) onSuccess;

  const GoogleOAuthScreen({super.key, required this.onSuccess});

  @override
  State<GoogleOAuthScreen> createState() => _GoogleOAuthScreenState();
}

class _GoogleOAuthScreenState extends State<GoogleOAuthScreen> {
  late WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: _handleNavigation,
        onPageFinished: (_) => setState(() => _loading = false),
      ))
      ..loadRequest(
        Uri.parse('https://www.elsfm.com/secure/auth/social/google/login'),
      );
  }

  void _handleNavigation(String url) {
    // BeMusic redirects to callback with ?token=xxx after successful OAuth
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final isCallback = url.contains('auth/social/google/callback') ||
        url.contains('auth/callback') ||
        url.contains('#/auth/');

    if (isCallback) {
      // Try to extract token from query params or fragment
      final token = uri.queryParameters['token'] ??
          uri.queryParameters['access_token'] ??
          (uri.fragment.contains('token=')
              ? Uri.splitQueryString(uri.fragment)['token']
              : null);

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess(token: token);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in with Google'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
