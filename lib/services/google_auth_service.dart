import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Uses Firebase's browser flow on web and Google's native account picker on mobile.
class GoogleAuthService {
  GoogleAuthService({this._auth, this._googleSignIn});

  final FirebaseAuth? _auth;
  final GoogleSignIn? _googleSignIn;

  Future<User?> signIn() async {
    final auth = _auth ?? FirebaseAuth.instance;
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..setCustomParameters({'prompt': 'select_account'});
        return (await auth.signInWithPopup(provider)).user;
      }

      final googleSignIn = _googleSignIn ?? GoogleSignIn(scopes: ['email']);
      final account = await googleSignIn.signIn();
      if (account == null) return null;

      final tokens = await account.authentication;
      if (tokens.idToken == null) {
        throw FirebaseAuthException(
          code: 'missing-google-id-token',
          message: 'Google did not return an ID token.',
        );
      }
      final credential = GoogleAuthProvider.credential(
        idToken: tokens.idToken,
        accessToken: tokens.accessToken,
      );
      return (await auth.signInWithCredential(credential)).user;
    } on FirebaseAuthException catch (error) {
      if (error.code == 'popup-closed-by-user' ||
          error.code == 'cancelled-popup-request' ||
          error.code == 'web-context-canceled') {
        return null;
      }
      rethrow;
    } on PlatformException catch (error) {
      if (error.code == 'sign_in_canceled') return null;
      rethrow;
    }
  }

  static String errorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'operation-not-allowed':
          return 'Google sign-in is not enabled in Firebase Authentication. Please contact support.';
        case 'unauthorized-domain':
          return 'This website is not authorized for Google sign-in. Please contact support.';
        case 'popup-blocked':
          return 'Allow pop-ups for this website, then try Google sign-in again.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with this email. Sign in using your original method.';
        case 'network-request-failed':
          return 'Check your internet connection and try Google sign-in again.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'missing-google-id-token':
        case 'invalid-credential':
          return 'Google sign-in configuration is incomplete. Please contact support.';
      }
    }
    if (error is PlatformException) {
      if (error.code == 'network_error') {
        return 'Check your internet connection and try Google sign-in again.';
      }
      if (error.code == 'sign_in_failed' || error.code == 'sign_in_required') {
        return 'Google sign-in could not start. Please check the Google Play services and Firebase OAuth configuration.';
      }
    }
    return 'Could not complete Google sign-in. Please try again.';
  }
}
