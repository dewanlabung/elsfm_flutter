import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GoogleOAuthScreen extends StatefulWidget {
  final void Function({String? token}) onSuccess;

  const GoogleOAuthScreen({super.key, required this.onSuccess});

  @override
  State<GoogleOAuthScreen> createState() => _GoogleOAuthScreenState();
}

class _GoogleOAuthScreenState extends State<GoogleOAuthScreen> {
  late WebViewController _controller;
  bool _loading = true;
  bool _completed = false;

  // Chrome 118 mobile UA bypasses Google's embedded-browser block
  static const _chromeUA =
      'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/118.0.0.0 Mobile Safari/537.36';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(_chromeUA)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: _onPageStarted,
        onPageFinished: _onPageFinished,
      ))
      ..loadRequest(
        Uri.parse('https://www.elsfm.com/secure/auth/social/google/login'),
      );
  }

  void _onPageStarted(String url) {
    setState(() => _loading = true);
    _checkForToken(url);
  }

  Future<void> _onPageFinished(String url) async {
    setState(() => _loading = false);
    await _checkForTokenJS(url);
  }

  void _checkForToken(String url) {
    if (_completed) return;

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final isCallback = url.contains('auth/social/google/callback') ||
        url.contains('auth/callback') ||
        url.contains('#/auth/') ||
        (url.contains('elsfm.com') && uri.queryParameters.containsKey('token'));

    if (!isCallback) return;

    final token = uri.queryParameters['token'] ??
        uri.queryParameters['access_token'] ??
        (uri.fragment.contains('token=')
            ? Uri.splitQueryString(uri.fragment)['token']
            : null);

    if (token != null) _finish(token);
  }

  // After BeMusic SPA loads, try to read auth token from localStorage
  Future<void> _checkForTokenJS(String url) async {
    if (_completed) return;
    if (!url.contains('elsfm.com')) return;

    try {
      final result = await _controller.runJavaScriptReturningResult('''
        (function() {
          var keys = ['be.auth_token', 'auth_token', 'token', 'access_token', 'lc'];
          for (var i = 0; i < keys.length; i++) {
            var v = localStorage.getItem(keys[i]);
            if (v && v.length > 10) return v;
          }
          // Check sessionStorage too
          for (var i = 0; i < keys.length; i++) {
            var v = sessionStorage.getItem(keys[i]);
            if (v && v.length > 10) return v;
          }
          return null;
        })()
      ''');

      final token = result.toString().replaceAll('"', '').trim();
      if (token.isNotEmpty && token != 'null' && token.length > 10) {
        _finish(token);
      }
    } catch (_) {}
  }

  void _finish(String token) {
    if (_completed) return;
    _completed = true;
    if (mounted) {
      Navigator.of(context).pop();
      widget.onSuccess(token: token);
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
