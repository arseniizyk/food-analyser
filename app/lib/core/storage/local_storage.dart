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
    _productsByBarcode[product['barcode']! as String] = product;
  }

  @override
  Future<Map<String, Object?>?> getProductByBarcode(String barcode) async {
    return _productsByBarcode[barcode];
  }

  @override
  Future<void> saveAnalysis(Map<String, Object?> analysis) async {
    _analyses[analysis['id']! as String] = analysis;
  }

  @override
  Future<List<Map<String, Object?>>> getHistory(String userId) async {
    return _analyses.values
        .where((analysis) => analysis['userId'] == userId)
        .toList()
      ..sort(
        (a, b) =>
            (b['createdAt']! as String).compareTo(a['createdAt']! as String),
      );
  }

  @override
  Future<Map<String, Object?>?> getAnalysisById(String analysisId) async {
    return _analyses[analysisId];
  }
}
