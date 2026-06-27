import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GoogleOAuthScreen extends StatefulWidget {
  final VoidCallback onSuccess;

  const GoogleOAuthScreen({
    super.key,
    required this.onSuccess,
  });

  @override
  State<GoogleOAuthScreen> createState() => _GoogleOAuthScreenState();
}

class _GoogleOAuthScreenState extends State<GoogleOAuthScreen> {
  late WebViewController webViewController;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            _checkForCallback(url);
          },
          onPageFinished: (String url) {
            setState(() => isLoading = false);
          },
        ),
      )
      ..loadRequest(
        Uri.parse('https://www.elsfm.com/secure/auth/social/google/login'),
      );
  }

  void _checkForCallback(String url) {
    if (url.contains('secure/auth/social/google/callback')) {
      widget.onSuccess();
      Navigator.of(context).pop();
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
          WebViewWidget(controller: webViewController),
          if (isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
