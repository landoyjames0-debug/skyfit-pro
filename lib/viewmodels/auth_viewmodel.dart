import 'package:flutter/material.dart';
import 'dart:async';
import '../repositories/auth_repository.dart';
import '../services/storage_service.dart';
import '../services/local_auth_service.dart';

// M1 - Global AuthViewModel: manages login state and theme.
// NOTE: Session timer is intentionally NOT here — it lives in HomeView
// so it can show the session-expired modal in the correct UI context.
class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();
  final StorageService _storage = StorageService();
  final LocalAuthService _localAuth = LocalAuthService();

  bool _isLoggedIn = false;
  bool _isLoading = true;
  String? _errorMessage;
  ThemeMode _themeMode = ThemeMode.system;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ThemeMode get themeMode => _themeMode;

  get currentUser => _repo.currentUser;

  AuthViewModel() {
    _init();
  }

  Future<void> _init() async {
    bool authResolved = false;

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

    final saved = await _storage.getThemeMode();
    if (saved == 'dark') _themeMode = ThemeMode.dark;
    if (saved == 'light') _themeMode = ThemeMode.light;
    notifyListeners();

    // Fallback: if Firebase auth doesn't respond in 5 seconds, stop loading
    await Future.delayed(const Duration(seconds: 5));
    if (!authResolved) {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Safe redirect after auth resolves - call from splash/home if needed
  void redirectToHomeIfLoggedIn(BuildContext context) {
    if (!isLoading && isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/home');
      });
    }
  }

  Future<bool> loginWithEmail(String email, String password) async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();
    try {
      await _repo.loginWithEmail(email: email, password: password);
      return true;
    } catch (e) {
      _errorMessage = _parseAuthError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerWithEmail(String email, String password,
      {String? name}) async {
    _errorMessage = null;
    try {
      final cred = await _repo.registerWithEmail(
        email: email,
        password: password,
        name: name,
      );
      await _repo.saveUserToFirestore(cred.user!);
      return true;
    } catch (e) {
      _errorMessage = _parseAuthError(e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _errorMessage = null;
    try {
      final cred = await _repo.signInWithGoogle();
      if (cred == null) return false;
      await _repo.saveUserToFirestore(cred.user!);
      return true;
    } catch (e) {
      _errorMessage = 'Google Sign-In failed. Try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    if (_localAuth.isLocked) {
      _errorMessage = 'Too many failed attempts. Please use password.';
      notifyListeners();
      return false;
    }
    return await _localAuth.authenticate();
  }

  Future<bool> isBiometricAvailable() => _localAuth.isAvailable();

  Future<void> signOut() async {
    await _storage.clearAll();
    await _repo.signOut();
    _isLoggedIn = false;
    notifyListeners();
  }

  void toggleTheme() async {
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

  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  String _parseAuthError(String error) {
    if (error.contains('user-not-found')) {
      return 'No account found with this email.';
    }
    if (error.contains('wrong-password')) {
      return 'Incorrect password.';
    }
    if (error.contains('email-already-in-use')) {
      return 'Email already registered.';
    }
    if (error.contains('weak-password')) {
      return 'Password is too weak.';
    }
    if (error.contains('invalid-email')) {
      return 'Invalid email address.';
    }
    return 'Authentication failed. Please try again.';
  }

  @override
  void dispose() {
    super.dispose();
  }
}
