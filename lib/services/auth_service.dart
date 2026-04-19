import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Stream of authentication state changes
  Stream<User?> get userChanges => _auth.authStateChanges();

  /// Gets the currently signed-in user
  User? get currentUser => _auth.currentUser;

  /// Signs in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Prompt the user to select a Google account
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('❌ [AuthService] Google Sign-In Error: $e');
      rethrow;
    }
  }

  /// Signs out of Firebase and Google
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
