// ignore: deprecated_member_use
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'dart:convert';

class BiometricWebService {
  /// Returns true if the browser supports WebAuthn (Chrome, Safari, Edge, Firefox)
  bool isSupported() {
    try {
      return js.context.callMethod('isWebAuthnSupported', []) == true;
    } catch (_) {
      return false;
    }
  }

  /// Registers a new passkey for [userId].
  /// Returns the credential ID (base64) to store in Firestore, or null on failure.
  Future<String?> register(String userId) async {
    try {
      final userIdBytes = utf8.encode(userId).toList();
      final result = await js.context.callMethod(
          'registerBiometric', [userId, js.JsArray.from(userIdBytes)]);
      return result as String?;
    } catch (e) {
      return null;
    }
  }

  /// Prompts the user to authenticate with a saved passkey.
  Future<bool> authenticate() async {
    try {
      final result =
          await js.context.callMethod('authenticateWithBiometric', []);
      return result == true;
    } catch (_) {
      return false;
    }
  }

  /// Authenticates using specific credential ID (for login flow).
  Future<bool> authenticateDetailed(String credIdBase64) async {
    try {
      final result = await js.context
          .callMethod('authenticateWithBiometricDetailed', [credIdBase64]);
      return result == true;
    } catch (e) {
      // ignore: avoid_print
      print('Web biometric detailed auth failed: $e');
      return false;
    }
  }
}
