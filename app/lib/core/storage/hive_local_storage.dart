import 'package:hive_flutter/hive_flutter.dart';

import 'local_storage.dart';

class HiveLocalStorage implements LocalStorage {
  HiveLocalStorage._({
    required this._productsBox,
    required this._analysesBox,
  });

  final Box<dynamic> _productsBox;
  final Box<dynamic> _analysesBox;

  static Future<HiveLocalStorage> create() async {
    final productsBox = await Hive.openBox<dynamic>('products');
    final analysesBox = await Hive.openBox<dynamic>('analyses');
    return HiveLocalStorage._(
      productsBox: productsBox,
      analysesBox: analysesBox,
    );
  }

  @override
  Future<void> saveProduct(Map<String, Object?> product) async {
    final barcode = product['barcode'] as String?;
    if (barcode == null || barcode.isEmpty) return;
    await _productsBox.put(barcode, product);
  }

  @override
  Future<Map<String, Object?>?> getProductByBarcode(String barcode) async {
    final raw = _productsBox.get(barcode);
    if (raw is Map) {
      return raw.cast<String, Object?>();
    }
    return null;
  }

  @override
  Future<void> saveAnalysis(Map<String, Object?> analysis) async {
    final barcode = analysis['barcode'] as String?;
    if (barcode == null || barcode.isEmpty) return;
    await _analysesBox.put(barcode, analysis);
  }

  @override
  Future<List<Map<String, Object?>>> getHistory(String userId) async {
    final items = _analysesBox.values
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
  Future<Map<String, Object?>?> getAnalysisById(String analysisId) async {
    final raw = _analysesBox.get(analysisId);
    if (raw is Map) {
      return raw.cast<String, Object?>();
    }
    return null;
  }
}
