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

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ThemeMode get themeMode => _themeMode;
  User? get currentUser => _repo.currentUser;

  AuthViewModel() {
    _init();
  }

  Future<void> _init() async {
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

  void redirectToHomeIfLoggedIn(BuildContext context) {
    if (!isLoading && isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/home');
      });
    }
  }

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

  Future<bool> isBiometricAvailable() async {
    if (kIsWeb) return _webBiometric.isSupported();
    return await _localAuth.isAvailable();
  }

  /// On mobile: always uses local biometric hardware — userVM not needed.
  /// On web: needs userVM to get the stored credential ID.
  Future<BiometricResult> authenticateWithBiometrics({
    UserViewModel? userVM,
  }) async {
    if (kIsWeb) {
      if (userVM?.user?.webCredentialId == null) {
        debugPrint('[AuthViewModel] Web biometrics: no credential ID');
        return BiometricResult.unavailable;
      }
      final ok = await _webBiometric
          .authenticateDetailed(userVM!.user!.webCredentialId!);
      return ok ? BiometricResult.success : BiometricResult.failed;
    }

    // Mobile path — no userVM needed
    if (_localAuth.isLocked) {
      _setError('Too many failed attempts. Please use your password.');
      return BiometricResult.locked;
    }

    return await _localAuth.authenticate();
  }

  Future<String?> registerWebBiometric(
      String userId, UserViewModel userVM) async {
    if (!kIsWeb) return null;
    final credId = await _webBiometric.register(userId);
    if (credId == null || userVM.user == null) return null;
    await userVM.updateProfile({'webCredentialId': credId});
    return credId;
  }

  void resetLocalAuthAttempts() => _localAuth.resetAttempts();

  Future<void> signOut() async {
    final uid = _repo.currentUser?.uid;
    _localAuth.resetAttempts();
    await Future.wait([_storage.clearAll(), _repo.signOut()]);
    if (uid != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_user_uid', uid);
    }
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _storage
        .setThemeMode(_themeMode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

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
      if (error == entry.key || error.contains(entry.key)) return entry.value;
    }
    return 'Something went wrong. Please try again.';
  }
}
