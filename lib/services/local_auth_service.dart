import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class LocalAuthService {
  // Only instantiate LocalAuthentication on non-web platforms.
  // local_auth is not supported on web and will throw at runtime if used.
  final LocalAuthentication? _auth = kIsWeb ? null : LocalAuthentication();

  int _failedAttempts = 0;
  static const int maxAttempts = 3;

  // ─── Availability ──────────────────────────────────────────────────────────
  Future<bool> isAvailable() async {
    if (kIsWeb) return false; // biometrics not supported on web
    try {
      return await _auth!.canCheckBiometrics && await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  // ─── Authenticate ──────────────────────────────────────────────────────────
  Future<bool> authenticate() async {
    // On web: biometrics are not available — return true to allow through
    // gracefully without crashing. The UI should never show a biometric
    // button on web since isAvailable() returns false.
    if (kIsWeb) return true;

    if (_failedAttempts >= maxAttempts) return false;

    try {
      final success = await _auth!.authenticate(
        localizedReason: 'Authenticate to access SkyFit Pro',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (success) {
        _failedAttempts = 0;
      } else {
        _failedAttempts++;
      }
      return success;
    } on PlatformException catch (e) {
      // Handle specific platform errors gracefully
      debugPrint(
          '[LocalAuthService] PlatformException: ${e.code} - ${e.message}');
      _failedAttempts++;
      return false;
    }
  }

  // ─── State ─────────────────────────────────────────────────────────────────
  bool get isLocked => _failedAttempts >= maxAttempts;
  void resetAttempts() => _failedAttempts = 0;
}
