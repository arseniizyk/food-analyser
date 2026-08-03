import 'package:hive_flutter/hive_flutter.dart';

import 'hive_bootstrap.dart';
import 'local_storage.dart';

class HiveLocalStorage implements LocalStorage {
  HiveLocalStorage._();

  Box<dynamic>? _productsBox;
  Box<dynamic>? _analysesBox;

  static HiveLocalStorage create() {
    return HiveLocalStorage._();
  }

  Future<void> warmUp() async {
    await Future.wait([_productsBoxReady(), _analysesBoxReady()]);
  }

  Future<Box<dynamic>> _productsBoxReady() async {
    await HiveBootstrap.ensureInitialized();
    return _productsBox ??= await Hive.openBox<dynamic>('products');
  }

  Future<Box<dynamic>> _analysesBoxReady() async {
    await HiveBootstrap.ensureInitialized();
    return _analysesBox ??= await Hive.openBox<dynamic>('analyses');
  }

  @override
  Future<void> saveProduct(Map<String, Object?> product) async {
    final barcode = product['barcode'] as String?;
    if (barcode == null || barcode.isEmpty) return;
    final productsBox = await _productsBoxReady();
    await productsBox.put(barcode, product);
  }

  @override
  Future<Map<String, Object?>?> getProductByBarcode(String barcode) async {
    final productsBox = await _productsBoxReady();
    final raw = productsBox.get(barcode);
    if (raw is Map) {
      return raw.cast<String, Object?>();
    }
    return null;
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
  Future<Map<String, Object?>?> getAnalysisById(String analysisId) async {
    final analysesBox = await _analysesBoxReady();
    final raw = analysesBox.get(analysisId);
    if (raw is Map) {
      return raw.cast<String, Object?>();
    }
    return null;
  }
}
