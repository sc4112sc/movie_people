import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Stream of authentication state changes (includes profile updates like photoURL)
  Stream<User?> get userChanges => _auth.userChanges();

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
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // 升級 Google 頭像解析度（s96 → s400），同時繞過舊快取
      final user = userCredential.user;
      if (user != null && user.photoURL != null) {
        final upgradedUrl = user.photoURL!.replaceAll(RegExp(r'=s\d+-c'), '=s400-c');
        if (upgradedUrl != user.photoURL) {
          await user.updatePhotoURL(upgradedUrl);
          await user.reload();
          debugPrint('✅ [AuthService] Upgraded Google photo: $upgradedUrl');
        } else {
          await user.reload();
        }
      }

      return userCredential;
    } catch (e) {
      debugPrint('❌ [AuthService] Google Sign-In Error: $e');
      rethrow;
    }
  }

  /// Signs in with Facebook
  Future<UserCredential?> signInWithFacebook() async {
    try {
      // Trigger the sign-in flow
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
      );

      if (result.status == LoginStatus.success) {
        final OAuthCredential credential =
            FacebookAuthProvider.credential(result.accessToken!.token);

        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);

        final user = userCredential.user;
        if (user != null) {
          // 無論如何都主動向 Facebook 拿最新的個人資料（含高品質頭像）
          try {
            final userData = await FacebookAuth.instance.getUserData(
              fields: "id,name,email,picture.type(large)",
            );
            final String? fbPhotoUrl = userData['picture']?['data']?['url'];
            debugPrint('🔍 [AuthService] FB userData picture url: $fbPhotoUrl');
            debugPrint('🔍 [AuthService] Current Firebase photoURL: ${user.photoURL}');
            if (fbPhotoUrl != null && fbPhotoUrl != user.photoURL) {
              await user.updatePhotoURL(fbPhotoUrl);
              await user.reload();
              debugPrint('🔍 [AuthService] Updated photoURL: ${_auth.currentUser?.photoURL}');
            }
          } catch (e) {
            debugPrint('⚠️ [AuthService] Failed to update FB photo: $e');
          }
        }

        return userCredential;
      } else if (result.status == LoginStatus.cancelled) {
        debugPrint('ℹ️ [AuthService] Facebook Sign-In Cancelled by user');
        return null;
      } else {
        debugPrint('❌ [AuthService] Facebook Sign-In Failed: ${result.message}');
        throw Exception(result.message);
      }
    } catch (e) {
      debugPrint('❌ [AuthService] Facebook Sign-In Error: $e');
      rethrow;
    }
  }

  /// Signs out of Firebase, Google and Facebook
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await FacebookAuth.instance.logOut();
    await _auth.signOut();
  }
}
