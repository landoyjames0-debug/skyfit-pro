import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/auth_repository.dart';
import '../services/storage_service.dart';
import '../services/local_auth_service.dart';
import '../services/biometric_web_service.dart';
import '../viewmodels/user_viewmodel.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();
  final StorageService _storage = StorageService();
  final LocalAuthService _localAuth = LocalAuthService();
  final BiometricWebService _webBiometric = BiometricWebService();

  bool _isLoggedIn = false;
  bool _isLoading = true;
  String? _errorMessage;
  ThemeMode _themeMode = ThemeMode.system;

  // ─── Getters ───────────────────────────────────────────────────────────────
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ThemeMode get themeMode => _themeMode;
  User? get currentUser => _repo.currentUser;

  // ─── Constructor ───────────────────────────────────────────────────────────
  AuthViewModel() {
    _init();
  }

  // ─── Initialization ────────────────────────────────────────────────────────
  Future<void> _init() async {
    // Clear any stale in-memory lock from a previous session
    _localAuth.resetAttempts();

    final saved = await _storage.getThemeMode();
    _themeMode = switch (saved) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
    notifyListeners();

    bool authResolved = false;

    Future.delayed(const Duration(seconds: 5), () {
      if (!authResolved) {
        _isLoading = false;
        notifyListeners();
      }
    });

    _repo.authStateChanges.listen((user) async {
      authResolved = true;
      _isLoggedIn = user != null;

      if (_isLoggedIn) {
        final token = await _repo.getIdToken();
        if (token != null) await _storage.saveToken(token);
      }

      _isLoading = false;
      notifyListeners();
    });
  }

  // ─── Navigation Helper ─────────────────────────────────────────────────────
  void redirectToHomeIfLoggedIn(BuildContext context) {
    if (!isLoading && isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/home');
      });
    }
  }

  // ─── Email Login ───────────────────────────────────────────────────────────
  Future<bool> loginWithEmail(String email, String password) async {
    _clearErrorAndSetLoading();
    try {
      await _repo.loginWithEmail(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _handleError(e.code);
      return false;
    } catch (e) {
      _handleError(e.toString());
      return false;
    }
  }

  // ─── Email Registration ────────────────────────────────────────────────────
  Future<bool> registerWithEmail(
    String email,
    String password, {
    String? name,
  }) async {
    _clearErrorAndSetLoading();
    try {
      final cred = await _repo.registerWithEmail(
        email: email,
        password: password,
        name: name,
      );
      await _repo.saveUserToFirestore(cred.user!);
      await _repo.loginWithEmail(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _handleError(e.code);
      return false;
    } catch (e) {
      _handleError(e.toString());
      return false;
    }
  }

  // ─── Google Sign-In ────────────────────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    _clearErrorAndSetLoading();
    try {
      final cred = await _repo.signInWithGoogle();
      if (cred == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      await _repo.saveUserToFirestore(cred.user!);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _handleError(e.code);
      return false;
    } catch (e) {
      _handleError('Google Sign-In failed. Try again.');
      return false;
    }
  }

  // ─── Biometrics ────────────────────────────────────────────────────────────

  /// Checks if the current platform supports biometric authentication.
  Future<bool> isBiometricAvailable() async {
    if (kIsWeb) return _webBiometric.isSupported();
    return await _localAuth.isAvailable();
  }

  /// Performs biometric authentication and returns a typed [BiometricResult]
  /// so callers can distinguish success / failed / cancelled / locked
  /// without inferring meaning from a bare bool.
  Future<BiometricResult> authenticateWithBiometrics(
      {UserViewModel? userVM}) async {
    if (kIsWeb) {
      if (userVM?.user?.webCredentialId == null) {
        debugPrint(
            '[AuthViewModel] Web biometrics: no credential ID, skipping');
        return BiometricResult.unavailable;
      }
      final ok = await _webBiometric
          .authenticateDetailed(userVM!.user!.webCredentialId!);
      return ok ? BiometricResult.success : BiometricResult.failed;
    }

    if (_localAuth.isLocked) {
      _setError('Too many failed attempts. Please use your password.');
      return BiometricResult.locked;
    }

    return await _localAuth.authenticate();
  }

  /// Web only — registers a new passkey for [userId] and saves credential ID
  /// to Firestore. Returns the base64 credential ID on success, null on failure.
  Future<String?> registerWebBiometric(
      String userId, UserViewModel userVM) async {
    if (!kIsWeb) return null;
    final credId = await _webBiometric.register(userId);
    if (credId == null || userVM.user == null) return null;
    await userVM.updateProfile({'webCredentialId': credId});
    return credId;
  }

  /// Resets the local biometric fail counter — call this after successful
  /// login or when the user re-enables biometrics from profile settings.
  void resetLocalAuthAttempts() => _localAuth.resetAttempts();

  // ─── Sign Out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    final uid = _repo.currentUser?.uid;

    // Reset biometric lock so the next login session starts clean
    _localAuth.resetAttempts();

    await Future.wait([_storage.clearAll(), _repo.signOut()]);

    // Re-save UID so the login screen can check biometric preference
    if (uid != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_user_uid', uid);
    }

    _isLoggedIn = false;
    notifyListeners();
  }

  // ─── Theme ─────────────────────────────────────────────────────────────────
  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _storage.setThemeMode(
      _themeMode == ThemeMode.dark ? 'dark' : 'light',
    );
    notifyListeners();
  }

  // ─── Error Helpers ─────────────────────────────────────────────────────────
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  void _handleError(String error) {
    _errorMessage = _parseAuthError(error);
    _isLoading = false;
    notifyListeners();
  }

  void _clearErrorAndSetLoading() {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();
  }

  // ─── Firebase Error Parser ─────────────────────────────────────────────────
  String _parseAuthError(String error) {
    const Map<String, String> errorMap = {
      'user-not-found': 'No account found with this email.',
      'wrong-password': 'Incorrect password.',
      'invalid-credential': 'Invalid email or password.',
      'invalid-email': 'Please enter a valid email address.',
      'email-already-in-use': 'An account with this email already exists.',
      'weak-password': 'Password must be at least 6 characters.',
      'too-many-requests': 'Too many attempts. Please try again later.',
      'user-disabled': 'This account has been disabled.',
      'network-request-failed': 'No internet connection. Please try again.',
      'operation-not-allowed': 'Sign-in method not enabled.',
      'credential-already-in-use':
          'This credential is already linked to another account.',
    };

    for (final entry in errorMap.entries) {
      if (error == entry.key || error.contains(entry.key)) {
        return entry.value;
      }
    }

    return 'Something went wrong. Please try again.';
  }
}
