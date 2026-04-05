import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricResult { success, failed, cancelled, locked, unavailable }

class LocalAuthService {
  final LocalAuthentication? _auth = kIsWeb ? null : LocalAuthentication();

  int _failedAttempts = 0;
  static const int maxAttempts = 3;

  bool get isLocked => _failedAttempts >= maxAttempts;

  void resetAttempts() => _failedAttempts = 0;

  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    try {
      return await _auth!.canCheckBiometrics && await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  Future<BiometricResult> authenticate() async {
    if (kIsWeb) return BiometricResult.unavailable;

    if (_failedAttempts >= maxAttempts) return BiometricResult.locked;

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
        return BiometricResult.success;
      }

      // Distinguish real failure from user cancellation:
      // if the sensor is still available, the user actively rejected.
      final stillAvailable =
          await _auth.canCheckBiometrics && await _auth.isDeviceSupported();

      if (!stillAvailable) return BiometricResult.cancelled;

      _failedAttempts++;
      return BiometricResult.failed;
    } on PlatformException catch (e) {
      debugPrint('[LocalAuthService] ${e.code}: ${e.message}');
      const cancelCodes = {
        'NotAvailable',
        'NotEnrolled',
        'LockedOut',
        'PermanentlyLockedOut',
        'SystemCancel',
        'UserCancel',
      };
      if (cancelCodes.contains(e.code)) return BiometricResult.cancelled;
      _failedAttempts++;
      return BiometricResult.failed;
    }
  }
}
