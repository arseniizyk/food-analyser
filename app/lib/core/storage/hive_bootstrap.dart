import 'package:hive_flutter/hive_flutter.dart';

class HiveBootstrap {
  HiveBootstrap._();

  static Future<void>? _initialization;

  static Future<void> ensureInitialized() {
    return _initialization ??= Hive.initFlutter();
  }
}
