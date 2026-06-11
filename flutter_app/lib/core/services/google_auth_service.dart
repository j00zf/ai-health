import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class GoogleAuthService {
  static Future<User?> signIn() async {
    try {
      if (kIsWeb) {
        GoogleAuthProvider provider = GoogleAuthProvider();

        final UserCredential userCredential =
            await FirebaseAuth.instance.signInWithPopup(
          provider,
        );

        return userCredential.user;
      }

      // Android/iOS implementation will be added later
      throw UnimplementedError(
        'Google Sign-In mobile implementation not added yet.',
      );
    } catch (e) {
      print("Google Sign In Error: $e");
      return null;
    }
  }

  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}