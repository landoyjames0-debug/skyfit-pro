import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveUserProfile(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  // ─── Biometric Methods ───────────────────────────────────────────────

  /// Save the credential ID after biometric registration
  Future<void> saveBiometricCredential(String uid, String credentialId) async {
    await _db.collection('users').doc(uid).update({
      'webCredentialId': credentialId,
      'biometricEnabled': true,
    });
  }

  /// Get the stored credential ID for biometric login
  Future<String?> getBiometricCredentialId(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data()?['webCredentialId'] as String?;
  }

  /// Clear biometric data (when user disables biometrics)
  Future<void> clearBiometricCredential(String uid) async {
    await _db.collection('users').doc(uid).update({
      'webCredentialId': null,
      'biometricEnabled': false,
    });
  }

  /// Check if biometric is enabled for a user
  Future<bool> isBiometricEnabled(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return false;
    return doc.data()?['biometricEnabled'] ?? false;
  }
}
