import 'package:hive_flutter/hive_flutter.dart';

import 'hive_bootstrap.dart';
import 'local_storage.dart';

class HiveLocalStorage implements LocalStorage {
  HiveLocalStorage._();

  Box<dynamic>? _analysesBox;

  static HiveLocalStorage create() {
    return HiveLocalStorage._();
  }

  Future<void> warmUp() async {
    await _analysesBoxReady();
  }

  Future<Box<dynamic>> _analysesBoxReady() async {
    await HiveBootstrap.ensureInitialized();
    return _analysesBox ??= await Hive.openBox<dynamic>('analyses');
  }

  @override
  Future<void> saveAnalysis(Map<String, Object?> analysis) async {
    final barcode = analysis['barcode'] as String?;
    if (barcode == null || barcode.isEmpty) return;
    final analysesBox = await _analysesBoxReady();
    await analysesBox.put(barcode, analysis);
  }

  @override
  Future<List<Map<String, Object?>>> getHistory(String userId) async {
    final analysesBox = await _analysesBoxReady();
    final items =
        analysesBox.values
            .whereType<Map>()
            .where((analysis) {
              if (userId.isEmpty) return true;
              return analysis['userId'] == userId;
            })
            .map((m) => m.cast<String, Object?>())
            .toList()
          ..sort((a, b) {
            final aDate = a['createdAt'] as String? ?? '';
            final bDate = b['createdAt'] as String? ?? '';
            return bDate.compareTo(aDate);
          });
    return items;
  }

  @override
  Future<Map<String, Object?>?> getAnalysisByBarcode(String barcode) async {
    final analysesBox = await _analysesBoxReady();
    final raw = analysesBox.get(barcode);
    if (raw is Map) {
      return raw.cast<String, Object?>();
    }
    return null;
  }
}
