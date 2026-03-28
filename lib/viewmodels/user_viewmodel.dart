import 'dart:io';
import 'dart:typed_data'; // ← add this
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class UserViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storage = StorageService();

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadUser(String uid) async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _firestoreService.getUserProfile(uid);
    } catch (e) {
      _errorMessage = 'Failed to load profile.';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createProfile(UserModel user) async {
    try {
      await _firestoreService.saveUserProfile(user);
      _user = user;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create profile.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    if (_user == null) return false;
    try {
      await _firestoreService.updateUserProfile(_user!.uid, updates);
      _user = UserModel.fromMap({..._user!.toMap(), ...updates});
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update profile.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleBiometric(bool enabled) async {
    await _storage.setBiometricEnabled(enabled);
    return await updateProfile({'biometricEnabled': enabled});
  }

  Future<bool> isBiometricEnabled() => _storage.isBiometricEnabled();

  /// Upload via file path (mobile only — uses dart:io File)
  Future<void> updateProfilePicture(String filePath) async {
    final uid = _user?.uid;
    if (uid == null) throw Exception('No user logged in');

    final file = File(filePath);
    final ext = filePath.split('.').last.toLowerCase();

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('profile_pictures')
        .child('$uid.$ext');

    final uploadTask = await storageRef.putFile(
      file,
      SettableMetadata(contentType: 'image/$ext'),
    );

    final downloadUrl = await uploadTask.ref.getDownloadURL();
    await _persistProfileUrl(uid, downloadUrl);
  }

  /// Upload via raw bytes (works on web + mobile — no dart:io needed in views)
  Future<void> updateProfilePictureFromBytes(
    Uint8List bytes, {
    String ext = 'jpg',
  }) async {
    final uid = _user?.uid;
    if (uid == null) throw Exception('No user logged in');

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('profile_pictures')
        .child('$uid.$ext');

    final uploadTask = await storageRef.putData(
      bytes,
      SettableMetadata(contentType: 'image/$ext'),
    );

    final downloadUrl = await uploadTask.ref.getDownloadURL();
    await _persistProfileUrl(uid, downloadUrl);
  }

  /// Shared helper — saves URL to Firestore and refreshes local model
  Future<void> _persistProfileUrl(String uid, String downloadUrl) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'profilePictureUrl': downloadUrl});

    _user = UserModel.fromMap({
      ..._user!.toMap(),
      'profilePictureUrl': downloadUrl,
    });
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
