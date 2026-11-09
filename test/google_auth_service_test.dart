import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_application_1/services/google_auth_service.dart';

class _User extends Fake implements User {}

class _Credential extends Fake implements UserCredential {
  _Credential(this.user);
  @override
  final User user;
}

class _Auth extends Fake implements FirebaseAuth {
  AuthCredential? receivedCredential;
  final signedInUser = _User();

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    receivedCredential = credential;
    return _Credential(signedInUser);
  }
}

class _Tokens extends Fake implements GoogleSignInAuthentication {
  _Tokens(this.idToken);
  @override
  final String? idToken;
  @override
  String get accessToken => 'google-access-token';
}

class _Account extends Fake implements GoogleSignInAccount {
  _Account(this.idToken);
  final String? idToken;
  @override
  Future<GoogleSignInAuthentication> get authentication async =>
      _Tokens(idToken);
}

class _GoogleSignIn extends GoogleSignIn {
  GoogleSignInAccount? account;
  Object? error;
  @override
  Future<GoogleSignInAccount?> signIn() async {
    if (error != null) throw error!;
    return account;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Exchanges Google tokens for a Firebase user', () async {
    final auth = _Auth();
    final google = _GoogleSignIn()..account = _Account('google-id-token');
    final user = await GoogleAuthService(
      auth: auth,
      googleSignIn: google,
    ).signIn();

    expect(user, same(auth.signedInUser));
    final credential = auth.receivedCredential as OAuthCredential;
    expect(credential.providerId, 'google.com');
    expect(credential.idToken, 'google-id-token');
    expect(credential.accessToken, 'google-access-token');
  });

  test('Cancelling the account picker does not authenticate', () async {
    final auth = _Auth();
    final service = GoogleAuthService(
      auth: auth,
      googleSignIn: _GoogleSignIn(),
    );
    expect(await service.signIn(), isNull);
    expect(auth.receivedCredential, isNull);
  });

  test('Native cancellation errors are handled quietly', () async {
    final google = _GoogleSignIn()
      ..error = PlatformException(code: 'sign_in_canceled');
    expect(
      await GoogleAuthService(auth: _Auth(), googleSignIn: google).signIn(),
      isNull,
    );
  });

  test('Missing ID tokens never reach Firebase credential exchange', () async {
    final auth = _Auth();
    final google = _GoogleSignIn()..account = _Account(null);
    await expectLater(
      GoogleAuthService(auth: auth, googleSignIn: google).signIn(),
      throwsA(
        isA<FirebaseAuthException>().having(
          (error) => error.code,
          'code',
          'missing-google-id-token',
        ),
      ),
    );
    expect(auth.receivedCredential, isNull);
  });

  test('Real provider failures propagate for the screen to display', () async {
    final failure = PlatformException(code: 'sign_in_failed');
    final google = _GoogleSignIn()..error = failure;
    await expectLater(
      GoogleAuthService(auth: _Auth(), googleSignIn: google).signIn(),
      throwsA(same(failure)),
    );
  });

  test('Errors explain provider setup and blocked browser popups', () {
    expect(
      GoogleAuthService.errorMessage(
        FirebaseAuthException(code: 'operation-not-allowed'),
      ),
      contains('not enabled'),
    );
    expect(
      GoogleAuthService.errorMessage(
        FirebaseAuthException(code: 'popup-blocked'),
      ),
      contains('Allow pop-ups'),
    );
    expect(
      GoogleAuthService.errorMessage(
        FirebaseAuthException(code: 'unauthorized-domain'),
      ),
      contains('not authorized'),
    );
  });
}
