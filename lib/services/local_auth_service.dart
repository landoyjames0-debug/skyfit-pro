import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

// M2 - Biometrics using local_auth package
class LocalAuthService {
  final LocalAuthentication _auth = LocalAuthentication();
  int _failedAttempts = 0;
  static const int maxAttempts = 3;

  Future<bool> isAvailable() async {
    try {
      return await _auth.canCheckBiometrics && await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  Future<bool> authenticate() async {
    if (_failedAttempts >= maxAttempts) return false;
    try {
      final success = await _auth.authenticate(
        localizedReason: 'Authenticate to access SkyFit Pro',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (!success) _failedAttempts++;
      if (success) _failedAttempts = 0;
      return success;
    } on PlatformException {
      _failedAttempts++;
      return false;
    }
  }

  bool get isLocked => _failedAttempts >= maxAttempts;
  void resetAttempts() => _failedAttempts = 0;
}
