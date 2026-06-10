import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// FOR ANDROID EMULATOR:
  /// static const String baseUrl = "http://10.0.2.2:8000";

  /// FOR REAL DEVICE:
  //static const String baseUrl = "http://192.168.8.122:8000";
  // static const String baseUrl = "http://192.168.100.219:8000";
  static const String baseUrl = "http://172.20.10.2:8000";

  Future<Map<String, dynamic>> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      throw Exception("Google sign-in cancelled");
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await _firebaseAuth
        .signInWithCredential(credential);

    final User? firebaseUser = userCredential.user;

    final String? idToken = await firebaseUser?.getIdToken();

    if (firebaseUser == null || idToken == null) {
      throw Exception("Failed to complete Google sign-in");
    }

    final backendData = await _saveUserToBackend(idToken);

    return {
      "email": (backendData["email"] ?? firebaseUser.email ?? "")
          .toString()
          .trim(),
      "name": (backendData["name"] ?? firebaseUser.displayName ?? "User")
          .toString()
          .trim(),
      "provider": "Google",
      "is_new_user": backendData["is_new_user"] == true,
    };
  }

  Future<Map<String, dynamic>> _saveUserToBackend(String idToken) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/google-login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"idToken": idToken}),
    );

    if (response.statusCode != 200) {
      throw Exception("Backend save failed: ${response.body}");
    }

    final Map<String, dynamic> data = jsonDecode(response.body);

    return data;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}
