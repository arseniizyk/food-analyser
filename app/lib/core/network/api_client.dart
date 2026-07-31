import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../storage/secure_storage.dart';

abstract interface class ApiClient {
  Future<Map<String, Object?>?> getProductByBarcode(String barcode);

  Future<Map<String, Object?>> analyzeProduct({
    required String barcode,
    required String imagePath,
    String? userId,
  });

  Future<Map<String, Object?>?> getAnalysisByBarcode(String barcode);
}

class FakeApiClient implements ApiClient {
  final Map<String, Map<String, Object?>> _productsByBarcode = {
    '460000000001': {
      'id': 'product-1',
      'barcode': '460000000001',
      'name': 'Protein Bar',
      'brand': 'Green Bite',
      'score': 86,
      'grade': 'good',
      'ingredients': ['oats', 'almonds', 'sugar', 'cocoa'],
      'createdAt': DateTime(2026, 1, 1).toIso8601String(),
    },
  };

  final Map<String, Map<String, Object?>> _analyses = {};

  @override
  Future<Map<String, Object?>?> getProductByBarcode(String barcode) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return _productsByBarcode[barcode];
  }

  @override
  Future<Map<String, Object?>> analyzeProduct({
    required String barcode,
    required String imagePath,
    String? userId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final score = 85;
    final analysis = {
      'id': 'analysis-${DateTime.now().microsecondsSinceEpoch}',
      'barcode': barcode,
      'userId': userId,
      'score': score,
      'grade': score >= 80 ? 'good' : 'average',
      'summary': ['Composition looks balanced.', 'No major risks detected.'],
      'risks': [],
      'ingredients': ['ingredient1', 'ingredient2'],
      'createdAt': DateTime.now().toIso8601String(),
    };

    _analyses[analysis['id']! as String] = analysis;
    return analysis;
  }

  @override
  Future<Map<String, Object?>?> getAnalysisByBarcode(String barcode) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _analyses.values.cast<Map<String, Object?>?>().firstWhere(
      (a) => a != null && a['barcode'] == barcode,
      orElse: () => null,
    );
  }
}

/// Real HTTP API client that communicates with backend services.
class HttpApiClient implements ApiClient {
  HttpApiClient({
    required this.baseUrl,
    required this._secureStorage,
  });

  final String baseUrl;
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
    try {
      final uri = Uri.parse('$baseUrl/api/v1/product/$barcode');
      final headers = await _authHeaders();
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 404) {
        return null;
      }
      if (response.statusCode != 200) {
        throw Exception('Failed to get product: ${response.statusCode}');
      }

      return jsonDecode(response.body) as Map<String, Object?>?;
    } catch (e) {
      throw Exception('Error getting product by barcode: $e');
    }
  }

  @override
  Future<Map<String, Object?>> analyzeProduct({
    required String barcode,
    required String imagePath,
    String? userId,
  }) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw FileSystemException('Image file not found: $imagePath');
      }

      final uri = Uri.parse('$baseUrl/api/v1/analyze/$barcode');
      final request = http.MultipartRequest('POST', uri);

      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      final headers = await _authHeaders();
      request.headers.addAll(headers);

      final response = await request.send().timeout(
        const Duration(seconds: 60),
      );

      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        throw Exception('Analyze request failed: ${response.statusCode} $body');
      }

      final responseBody = await response.stream.bytesToString();
      return jsonDecode(responseBody) as Map<String, Object?>;
    } catch (e) {
      throw Exception('Error analyzing product: $e');
    }
  }

  @override
  Future<Map<String, Object?>?> getAnalysisByBarcode(String barcode) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/product/$barcode');
      final headers = await _authHeaders();
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 404) {
        return null;
      }
      if (response.statusCode != 200) {
        throw Exception('Failed to get analysis: ${response.statusCode}');
      }

      return jsonDecode(response.body) as Map<String, Object?>?;
    } catch (e) {
      throw Exception('Error getting analysis: $e');
    }
  }
}
