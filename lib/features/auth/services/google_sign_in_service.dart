import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInResult {
  final String? email;
  final String? displayName;
  final String? photoUrl;
  // accessToken is sent to BeMusic backend via ?tokenFromApi= param.
  // BeMusic calls Socialite::driver('google')->userFromToken($accessToken)
  final String? accessToken;

  GoogleSignInResult({
    this.email,
    this.displayName,
    this.photoUrl,
    this.accessToken,
  });
}

/// Google Sign-In — no Firebase required.
/// Gets the OAuth access token and sends it to the BeMusic backend at
/// GET /api/v1/auth/social/google/callback?tokenFromApi={accessToken}
class GoogleSignInService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  Future<GoogleSignInResult> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) throw Exception('Google sign-in cancelled');

    final auth = await account.authentication;
    if (auth.accessToken == null) {
      throw Exception('Failed to get Google access token');
    }

    return GoogleSignInResult(
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
      accessToken: auth.accessToken,
    );
  }

  Future<void> signOut() => _googleSignIn.signOut();

  Future<bool> isSignedIn() => _googleSignIn.isSignedIn();

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
}
