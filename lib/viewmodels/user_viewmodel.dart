import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
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

  Future<bool> isBiometricEnabled() async =>
      _user?.biometricEnabled ?? await _storage.isBiometricEnabled();

  /// Mobile-only Storage upload (web uses base64)
  Future<void> updateProfilePicture(String filePath) async {
    if (kIsWeb) return;
    final uid = _user?.uid;
    if (uid == null) throw Exception('No user logged in');

    final fileBytes = await File(filePath).readAsBytes();
    final ext = filePath.split('.').last.toLowerCase();

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('profile_pictures')
        .child('$uid.$ext');

    final uploadTask = await storageRef.putData(
      fileBytes,
      SettableMetadata(contentType: 'image/$ext'),
    );

    final downloadUrl = await uploadTask.ref.getDownloadURL();
    await _persistProfileUrl(uid, downloadUrl);
  }

  /// Web: Base64 image direct to Firestore (free tier OK!)
  Future<void> updateProfilePictureFromBytes(
    Uint8List bytes, {
    String ext = 'jpg',
  }) async {
    final uid = _user?.uid;
    if (uid == null) throw Exception('No user logged in');

    final base64Image = 'data:image/$ext;base64,${base64Encode(bytes)}';

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'profilePictureUrl': base64Image});

    _user = _user!.copyWith(profilePictureUrl: base64Image);
    notifyListeners();
  }

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
