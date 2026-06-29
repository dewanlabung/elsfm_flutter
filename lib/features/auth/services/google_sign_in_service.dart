import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInResult {
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? idToken;
  final String? accessToken;

  GoogleSignInResult({
    this.email,
    this.displayName,
    this.photoUrl,
    this.idToken,
    this.accessToken,
  });
}

/// Native Google Sign-In using device accounts (no WebView, no Firebase needed).
/// Requires google-services.json and the app registered in Google Cloud Console.
class GoogleSignInService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  Future<GoogleSignInResult> signInWithGoogle() async {
    // Sign out first to always show account picker
    try { await _googleSignIn.signOut(); } catch (_) {}

    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw Exception('Google Sign-In cancelled');
    }

    final auth = await account.authentication;
    return GoogleSignInResult(
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
      idToken: auth.idToken,
      accessToken: auth.accessToken,
    );
  }

  Future<void> signOut() async {
    try { await _googleSignIn.signOut(); } catch (_) {}
  }
}
