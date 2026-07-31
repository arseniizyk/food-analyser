abstract interface class LocalStorage {
  Future<void> saveProduct(Map<String, Object?> product);

  Future<Map<String, Object?>?> getProductByBarcode(String barcode);

  Future<void> saveAnalysis(Map<String, Object?> analysis);

  Future<List<Map<String, Object?>>> getHistory(String userId);

  Future<Map<String, Object?>?> getAnalysisById(String analysisId);
}

class MemoryLocalStorage implements LocalStorage {
  final Map<String, Map<String, Object?>> _productsByBarcode = {};
  final Map<String, Map<String, Object?>> _analyses = {};

  @override
  Future<void> saveProduct(Map<String, Object?> product) async {
    final barcode = product['barcode'] as String?;
    if (barcode == null || barcode.isEmpty) return;
    _productsByBarcode[barcode] = product;
  }

  @override
  Future<Map<String, Object?>?> getProductByBarcode(String barcode) async {
    return _productsByBarcode[barcode];
  }

  @override
  Future<void> saveAnalysis(Map<String, Object?> analysis) async {
    final barcode = analysis['barcode'] as String?;
    if (barcode == null || barcode.isEmpty) return;
    _analyses[barcode] = analysis;
  }

  @override
  Future<List<Map<String, Object?>>> getHistory(String userId) async {
    return _analyses.values
        .where((analysis) {
          if (userId.isEmpty) return true;
          return analysis['userId'] == userId;
        })
        .toList()
      ..sort((a, b) {
        final aDate = a['createdAt'] as String? ?? '';
        final bDate = b['createdAt'] as String? ?? '';
        return bDate.compareTo(aDate);
      });
  }

  @override
  Future<Map<String, Object?>?> getAnalysisById(String analysisId) async {
    return _analyses[analysisId];
  }
}
