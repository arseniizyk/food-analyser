import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'secure_storage.dart';

/// SecureStorage backed by the platform keystore/Keychain via
/// flutter_secure_storage (replaces the plain-Hive implementation
/// that stored tokens insecurely).
class FlutterSecureStorageImpl implements SecureStorage {
  FlutterSecureStorageImpl._();

  static const _storage = FlutterSecureStorage();

  static FlutterSecureStorageImpl create() {
    return FlutterSecureStorageImpl._();
  }

  /// Probe availability so first reads don't pay the platform init cost.
  Future<void> warmUp() async {
    try {
      await _storage.read(key: '_warmup');
    } catch (_) {
      // Availability probe only; real operations surface their own errors.
    }
  }

  @override
  Future<void> write(String key, String value) {
    return _storage.write(key: key, value: value);
  }

  @override
  Future<String?> read(String key) {
    return _storage.read(key: key);
  }

  @override
  Future<void> delete(String key) {
    return _storage.delete(key: key);
  }
}