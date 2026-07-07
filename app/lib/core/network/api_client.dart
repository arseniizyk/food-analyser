import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

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

  Future<String?> ocrRecognizeImage(String imagePath);
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

  @override
  Future<String?> ocrRecognizeImage(String imagePath) async {
    // Fake implementation: parse ingredients from image path or return placeholder.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    // In real implementation, this would upload the image bytes to OCR service.
    return _parseIngredients(imagePath).join(', ');
  }

  List<String> _parseIngredients(String text) {
    return text
        .split(RegExp(r'[,;\n]'))
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}

/// Real HTTP API client that communicates with backend services.
class HttpApiClient implements ApiClient {
  HttpApiClient({
    required this.baseUrl,
    required this.ocrServiceUrl,
    required SecureStorage secureStorage,
  }) : _secureStorage = secureStorage;

  final String baseUrl;
  final String ocrServiceUrl;
  final SecureStorage _secureStorage;

  Future<Map<String, String>> _authHeaders() async {
    final token = await _secureStorage.read('access_token');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  @override
  Future<Map<String, Object?>?> getProductByBarcode(String barcode) async {
    // TODO: Implement real API call
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return null;
  }

  @override
  Future<Map<String, Object?>> createProductFromIngredients({
    required String barcode,
    required String ingredientsText,
  }) async {
    // TODO: Implement real API call
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return {
      'id': 'product-${DateTime.now().microsecondsSinceEpoch}',
      'barcode': barcode,
      'name': 'Unknown product',
      'brand': null,
      'imageUrl': null,
      'ingredients': ingredientsText.split(','),
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<Map<String, Object?>> analyzeProduct({
    required String productId,
    required String userId,
    required String ingredientsText,
  }) async {
    // TODO: Implement real API call
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return {
      'id': 'analysis-${DateTime.now().microsecondsSinceEpoch}',
      'productId': productId,
      'userId': userId,
      'score': {'value': 80, 'label': 'good'},
      'risks': [],
      'summary': ['Composition looks balanced.'],
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<List<Map<String, Object?>>> getHistory(String userId) async {
    // TODO: Implement real API call
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return [];
  }

  @override
  Future<Map<String, Object?>?> getAnalysisById(String analysisId) async {
    // TODO: Implement real API call
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return null;
  }

  @override
  Future<String?> ocrRecognizeImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw FileSystemException('File not found: $imagePath');
      }
      final uri = Uri.parse('$ocrServiceUrl/ocr');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', imagePath));

      // Attach auth header if present
      final headers = await _authHeaders();
      request.headers.addAll(headers);

      final response = await request.send();

      if (response.statusCode != 200) {
        throw Exception(
          'OCR request failed with status ${response.statusCode}',
        );
      }

      final responseData = await response.stream.bytesToString();
      return responseData;
    } catch (e) {
      throw Exception('OCR request failed: $e');
    }
  }

  // Note: other methods (getProductByBarcode, createProductFromIngredients,
  // analyzeProduct, getHistory, getAnalysisById) are TODO and should use
  // `_authHeaders()` to include `Authorization` header when implemented.
}
