import 'dart:async';

abstract interface class ApiClient {
  Future<Map<String, Object?>?> getProductByBarcode(String barcode);

  Future<Map<String, Object?>> createProductFromIngredients({
    required String barcode,
    required String ingredientsText,
  });

  Future<Map<String, Object?>> analyzeProduct({
    required String productId,
    required String userId,
    required String ingredientsText,
  });

  Future<List<Map<String, Object?>>> getHistory(String userId);

  Future<Map<String, Object?>?> getAnalysisById(String analysisId);
}

class FakeApiClient implements ApiClient {
  final Map<String, Map<String, Object?>> _productsByBarcode = {
    '460000000001': {
      'id': 'product-1',
      'barcode': '460000000001',
      'name': 'Protein Bar',
      'brand': 'Green Bite',
      'imageUrl': null,
      'ingredients': ['oats', 'almonds', 'sugar', 'cocoa'],
      'createdAt': DateTime(2026, 1, 1).toIso8601String(),
      'updatedAt': DateTime(2026, 1, 1).toIso8601String(),
    },
  };

  final Map<String, Map<String, Object?>> _analyses = {};

  @override
  Future<Map<String, Object?>?> getProductByBarcode(String barcode) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return _productsByBarcode[barcode];
  }

  @override
  Future<Map<String, Object?>> createProductFromIngredients({
    required String barcode,
    required String ingredientsText,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));

    final ingredients = _parseIngredients(ingredientsText);
    final product = {
      'id': 'product-${DateTime.now().microsecondsSinceEpoch}',
      'barcode': barcode,
      'name': 'Unknown product',
      'brand': null,
      'imageUrl': null,
      'ingredients': ingredients,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    _productsByBarcode[barcode] = product;
    return product;
  }

  @override
  Future<Map<String, Object?>> analyzeProduct({
    required String productId,
    required String userId,
    required String ingredientsText,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final ingredients = _parseIngredients(ingredientsText);
    final risky = ingredients
        .where((item) => item.contains('sugar') || item.contains('color'))
        .toList();
    final score = risky.isEmpty ? 86 : 58;
    final analysis = {
      'id': 'analysis-${DateTime.now().microsecondsSinceEpoch}',
      'productId': productId,
      'userId': userId,
      'score': {'value': score, 'label': score >= 80 ? 'good' : 'medium'},
      'risks': risky
          .map(
            (item) => {
              'ingredient': item,
              'level': item.contains('sugar') ? 'medium' : 'high',
              'reason': item.contains('sugar')
                  ? 'High sugar intake can be undesirable in daily diet.'
                  : 'Artificial colorants may be sensitive for some users.',
            },
          )
          .toList(),
      'summary': [
        score >= 80
            ? 'Composition looks balanced.'
            : 'Composition has ingredients worth checking.',
        'Detected ${ingredients.length} ingredients.',
      ],
      'createdAt': DateTime.now().toIso8601String(),
    };

    _analyses[analysis['id']! as String] = analysis;
    return analysis;
  }

  @override
  Future<List<Map<String, Object?>>> getHistory(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
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
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _analyses[analysisId];
  }

  List<String> _parseIngredients(String text) {
    return text
        .split(RegExp(r'[,;\n]'))
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
