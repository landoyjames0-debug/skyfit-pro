import 'dart:js_interop';
import 'dart:convert';
import 'package:flutter/foundation.dart';

// JS interop declarations
@JS('isWebAuthnSupported')
external bool _isWebAuthnSupported();

@JS('registerBiometric')
external JSPromise<JSAny?> _registerBiometric(
    String userId, JSArray<JSNumber> userIdBytes);

@JS('authenticateWithBiometric')
external JSPromise<JSAny?> _authenticateWithBiometric();

@JS('authenticateWithBiometricDetailed')
external JSPromise<JSAny?> _authenticateWithBiometricDetailed(
    String credIdBase64);

class BiometricWebService {
  bool isSupported() {
    try {
      return _isWebAuthnSupported();
    } catch (_) {
      return false;
    }
  }

  Future<String?> register(String userId) async {
    try {
      final userIdBytes = utf8.encode(userId);
      final jsBytes = userIdBytes.map((b) => b.toJS).toList().toJS;

      final result = await _registerBiometric(userId, jsBytes).toDart;
      return result?.dartify() as String?;
    } catch (e) {
      debugPrint('WebAuthn register error: $e');
      return null;
    }
  }

  Future<bool> authenticate() async {
    try {
      final result = await _authenticateWithBiometric().toDart;
      return result?.dartify() == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateDetailed(String credIdBase64) async {
    try {
      final result =
          await _authenticateWithBiometricDetailed(credIdBase64).toDart;
      return result?.dartify() == true;
    } catch (e) {
      debugPrint('Web biometric detailed auth failed: $e');
      return false;
    }
  }
}
