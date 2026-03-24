import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// M2 - Security: Uses flutter_secure_storage (AES encrypted), NOT SharedPreferences
class StorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _tokenKey = 'auth_token';
  static const _biometricKey = 'biometric_enabled';
  static const _themeKey = 'theme_mode';

  Future<void> saveToken(String token) async =>
      await _storage.write(key: _tokenKey, value: token);

  Future<String?> getToken() async => await _storage.read(key: _tokenKey);

  Future<void> deleteToken() async => await _storage.delete(key: _tokenKey);

  Future<void> setBiometricEnabled(bool enabled) async =>
      await _storage.write(key: _biometricKey, value: enabled.toString());

  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _biometricKey);
    return val == 'true';
  }

  Future<void> setThemeMode(String mode) async =>
      await _storage.write(key: _themeKey, value: mode);

  Future<String?> getThemeMode() async => await _storage.read(key: _themeKey);

  Future<void> clearAll() async => await _storage.deleteAll();
}
