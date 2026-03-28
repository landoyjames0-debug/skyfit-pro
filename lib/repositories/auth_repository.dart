import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Lazy GoogleSignIn (mobile only) ──────────────────────────────────────
  // Not instantiated on web — avoids the duplicate google.accounts.id.initialize()
  // warning caused by the google_sign_in_web plugin registering on startup.
  GoogleSignIn? _googleSignInInstance;
  GoogleSignIn get _googleSignIn {
    assert(!kIsWeb, 'GoogleSignIn should not be used on web.');
    return _googleSignInInstance ??= GoogleSignIn(
      scopes: ['email', 'profile'],
    );
  }

  // ─── Current User ──────────────────────────────────────────────────────────
  User? get currentUser => _auth.currentUser;

  // ─── Auth State Stream ─────────────────────────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Get ID Token ──────────────────────────────────────────────────────────
  Future<String?> getIdToken() async {
    return await _auth.currentUser?.getIdToken();
  }

  // ─── Email Login ───────────────────────────────────────────────────────────
  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ─── Email Register ────────────────────────────────────────────────────────
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    String? name,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (name != null && name.isNotEmpty) {
      await cred.user?.updateDisplayName(name.trim());
    }
    return cred;
  }

  // ─── Google Sign-In ────────────────────────────────────────────────────────
  // Web:    uses Firebase signInWithPopup (no google_sign_in package needed)
  // Mobile: uses google_sign_in package → signInWithCredential
  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');
      return await _auth.signInWithPopup(googleProvider);
    }

    // Mobile flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // user cancelled

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  // ─── Save User to Firestore ────────────────────────────────────────────────
  // Only writes on first login — does not overwrite existing data
  Future<void> saveUserToFirestore(User user) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();
    if (!doc.exists) {
      await docRef.set({
        'uid': user.uid,
        'fullName': user.displayName ?? '',
        'email': user.email ?? '',
        'profilePictureUrl': user.photoURL ?? '',
        'weightKg': 0.0,
        'age': 0,
        'biometricEnabled': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ─── Sign Out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    if (!kIsWeb) {
      // Use the instance directly to avoid creating one just to sign out
      await _googleSignInInstance?.signOut();
    }
    await _auth.signOut();
  }
}
