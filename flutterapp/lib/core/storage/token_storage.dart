import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the JWT in the platform keystore/keychain.
abstract class TokenStorage {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'access_token';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() async {
    try {
      return await _storage.read(key: _key);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
  }
}

/// In-memory implementation used by tests.
class MemoryTokenStorage implements TokenStorage {
  MemoryTokenStorage([this._token]);
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}

/// Web implementation (browser localStorage via SharedPreferences).
class PrefsTokenStorage implements TokenStorage {
  PrefsTokenStorage(this._prefs);
  static const _key = 'access_token';
  final SharedPreferences _prefs;

  @override
  Future<String?> read() async => _prefs.getString(_key);

  @override
  Future<void> write(String token) => _prefs.setString(_key, token);

  @override
  Future<void> clear() => _prefs.remove(_key);
}
