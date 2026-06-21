import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Make sure this is imported

class GoogleAuthService {
  // Initialize GoogleSignIn instance
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static Future<User?> signIn() async {
    try {
      if (kIsWeb) {
        GoogleAuthProvider provider = GoogleAuthProvider();
        final UserCredential userCredential =
            await FirebaseAuth.instance.signInWithPopup(provider);
        return userCredential.user;
      }

      // 🚀 NATIVE MOBILE IMPLEMENTATION (Android / iOS)
      // Step 1: Trigger the native Google Account Picker overlay
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled the sign-in flow
        return null;
      }

      // Step 2: Extract authentication details (tokens) from the selected account
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Step 3: Bundle tokens into a Firebase Credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Step 4: Securely log in to Firebase using that credential
      final UserCredential userCredential = 
          await FirebaseAuth.instance.signInWithCredential(credential);

      return userCredential.user;
    } catch (e) {
      print("Google Sign In Error: $e");
      return null;
    }
  }

  static Future<void> signOut() async {
    // Disconnect both Firebase and the native Google Client session caches
    await FirebaseAuth.instance.signOut();
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
  }
}