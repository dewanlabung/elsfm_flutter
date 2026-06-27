import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoogleSignInResult {
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? idToken;

  GoogleSignInResult({
    this.email,
    this.displayName,
    this.photoUrl,
    this.idToken,
  });
}

/// Google Sign-In service for authentication
class GoogleSignInService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Sign in with Google and get authentication details
  Future<GoogleSignInResult> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw Exception('Google Sign-In cancelled by user');
      }

      final auth = await account.authentication;
      if (auth.idToken == null) {
        throw Exception('Failed to get Google ID token');
      }

      return GoogleSignInResult(
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
        idToken: auth.idToken,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  /// Check if user is currently signed in
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  /// Get current signed-in account
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
}
