import 'package:hive_flutter/hive_flutter.dart';
import 'secure_storage.dart';

class HiveSecureStorage implements SecureStorage {
  HiveSecureStorage._(this._box);

  final Box<dynamic> _box;

  static Future<HiveSecureStorage> create() async {
    final box = await Hive.openBox<dynamic>('auth');
    return HiveSecureStorage._(box);
  }

  @override
  Future<void> write(String key, String value) async {
    await _box.put(key, value);
  }

  @override
  Future<String?> read(String key) async {
    return _box.get(key) as String?;
  }

  @override
  Future<void> delete(String key) async {
    await _box.delete(key);
  }
}
