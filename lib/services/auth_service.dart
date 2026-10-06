import 'package:firebase_auth/firebase_auth.dart';

/// Firebase phone-number (OTP) authentication.
class AuthService {
  AuthService([FirebaseAuth? auth]) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Stream<User?> get authState => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Sends an OTP to [phoneNumber] (E.164 format). [onCodeSent] receives the
  /// verification id needed by [verifyOtp]. On Android the SMS may be
  /// auto-retrieved, in which case the user is signed in without typing it.
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String message) onError,
    int? resendToken,
    void Function(int? token)? onResendToken,
  }) {
    return _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      forceResendingToken: resendToken,
      verificationCompleted: (credential) async {
        try {
          await _auth.signInWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          onError(describeAuthError(e));
        }
      },
      verificationFailed: (e) => onError(describeAuthError(e)),
      codeSent: (id, token) {
        onResendToken?.call(token);
        onCodeSent(id);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> verifyOtp(String verificationId, String smsCode) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() => _auth.signOut();
}

String describeAuthError(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-phone-number':
      return 'That phone number is not valid.';
    case 'invalid-verification-code':
      return 'Incorrect OTP. Please try again.';
    case 'session-expired':
      return 'The OTP has expired. Request a new one.';
    case 'too-many-requests':
      return 'Too many attempts. Please wait a while and retry.';
    case 'network-request-failed':
      return 'No internet connection.';
    default:
      return e.message ?? 'Authentication failed (${e.code}).';
  }
}
