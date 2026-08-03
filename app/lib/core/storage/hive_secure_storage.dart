import 'package:hive_flutter/hive_flutter.dart';

import 'hive_bootstrap.dart';
import 'secure_storage.dart';

class HiveSecureStorage implements SecureStorage {
  HiveSecureStorage._();

  Box<dynamic>? _box;

  static HiveSecureStorage create() {
    return HiveSecureStorage._();
  }

  Future<void> warmUp() async {
    await _boxReady();
  }

  Future<Box<dynamic>> _boxReady() async {
    await HiveBootstrap.ensureInitialized();
    return _box ??= await Hive.openBox<dynamic>('auth');
  }

  @override
  Future<void> write(String key, String value) async {
    final box = await _boxReady();
    await box.put(key, value);
  }

  @override
  Future<String?> read(String key) async {
    final box = await _boxReady();
    return box.get(key) as String?;
  }

  @override
  Future<void> delete(String key) async {
    final box = await _boxReady();
    await box.delete(key);
  }
}
