import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn =
      GoogleSignIn.instance;

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (!_initialized) {
      await _googleSignIn.initialize(
        clientId:
            '316580441902-h843io0qgdoouebcbiir69o7flrj811q.apps.googleusercontent.com',
      );

      _initialized = true;
    }
  }

  static Future<GoogleSignInAccount?>
      signIn() async {
    try {
      await initialize();

      return await _googleSignIn.authenticate();
    } catch (e) {
      print(
        "Google Sign In Error: $e",
      );

      return null;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}