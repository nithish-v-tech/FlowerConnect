import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  static FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  static String? _verificationId;
  static int? _resendToken;

  /// Stream of Firebase Auth changes
  static Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? const Stream.empty();

  /// Current authenticated Firebase User
  static User? get currentFirebaseUser {
    try {
      return _auth?.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Trigger Firebase Phone Auth OTP
  /// On Firebase Spark Plan, test phone numbers configured in Firebase Console
  /// bypass real carrier SMS, cost 0 quota, and succeed instantly!
  static Future<Map<String, dynamic>> sendPhoneOtp({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onVerificationFailed,
  }) async {
    final auth = _auth;
    if (auth == null) {
      return {'status': 'no_app'};
    }

    try {
      final completer = Completer<Map<String, dynamic>>();

      await auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 30),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Instant auto-retrieval (Android only)
          try {
            final userCredential = await auth.signInWithCredential(credential);
            if (!completer.isCompleted) {
              completer.complete({
                'status': 'auto_verified',
                'user': userCredential.user,
              });
            }
          } catch (e) {
            debugPrint('[FirebaseAuthService] Auto verification error: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('[FirebaseAuthService] Verification failed: ${e.message} (${e.code})');
          onVerificationFailed(e.message ?? 'Phone verification failed.');
          if (!completer.isCompleted) {
            completer.complete({
              'status': 'error',
              'message': e.message,
              'code': e.code,
            });
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          debugPrint('[FirebaseAuthService] OTP Code sent. VerificationId: $verificationId');
          onCodeSent(verificationId);
          if (!completer.isCompleted) {
            completer.complete({
              'status': 'code_sent',
              'verification_id': verificationId,
            });
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        forceResendingToken: _resendToken,
      );

      return await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => {
          'status': 'code_sent',
          'verification_id': _verificationId ?? 'demo_verification_id',
        },
      );
    } catch (e) {
      debugPrint('[FirebaseAuthService] sendPhoneOtp fallback error: $e');
      return {
        'status': 'fallback',
        'message': e.toString(),
      };
    }
  }

  /// Verify entered 6-digit OTP code against Firebase Auth
  static Future<UserCredential?> verifyOtpCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final auth = _auth;
    if (auth == null) return null;

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final userCredential = await auth.signInWithCredential(credential);
      debugPrint('[FirebaseAuthService] Firebase Sign-in success: ${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('[FirebaseAuthService] verifyOtpCode error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[FirebaseAuthService] Generic verify error: $e');
      return null;
    }
  }

  /// Sign out from Firebase Auth
  static Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } catch (e) {
      debugPrint('[FirebaseAuthService] signOut error: $e');
    }
  }
}
