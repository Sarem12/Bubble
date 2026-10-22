import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();
  
  static const _sessionTokenKey = 'session_token';
  static const _accessTokenKey = 'access_token';
  static const _deviceIdKey = 'device_id';
  static const _deviceNameKey = 'device_name';

  static String? _cachedSessionToken;
  static bool _hasLoadedSession = false;

  static String? get cachedSessionToken => _cachedSessionToken;
  static bool get hasLoadedSession => _hasLoadedSession;

  static const String defaultDeviceId = 'bubble_mobile_device_001';
  static const String defaultDeviceName = 'Mobile Device';

  static Future<void> init() async {
    if (!_hasLoadedSession) {
      _cachedSessionToken = await _storage.read(key: _sessionTokenKey);
      _hasLoadedSession = true;
    }
  }

  static Future<void> saveSessionToken(String token) async {
    _cachedSessionToken = token;
    _hasLoadedSession = true;
    await _storage.write(key: _sessionTokenKey, value: token);
  }

  static Future<String?> getSessionToken() async {
    if (_hasLoadedSession) return _cachedSessionToken;
    _cachedSessionToken = await _storage.read(key: _sessionTokenKey);
    _hasLoadedSession = true;
    return _cachedSessionToken;
  }

  static Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  static Future<String> getDeviceId() async {
    final id = await _storage.read(key: _deviceIdKey);
    if (id == null || id.isEmpty) {
      final newId = const Uuid().v4();
      await _storage.write(key: _deviceIdKey, value: newId);
      return newId;
    }
    return id;
  }

  static Future<String> getDeviceName() async {
    final name = await _storage.read(key: _deviceNameKey);
    if (name == null || name.isEmpty) {
      await _storage.write(key: _deviceNameKey, value: defaultDeviceName);
      return defaultDeviceName;
    }
    return name;
  }

  static Future<void> clearAuth() async {
    _cachedSessionToken = null;
    _hasLoadedSession = true;
    await _storage.delete(key: _sessionTokenKey);
    await _storage.delete(key: _accessTokenKey);
  }

  static Future<void> clearAll() async {
    await clearAuth();
  }
}
