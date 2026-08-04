import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'api_error.dart';
import '../storage/secure_storage.dart';

abstract interface class ApiClient {
  Future<Map<String, Object?>> analyze({
    required String barcode,
    required String imagePath,
    String? userId,
  });

  Future<Map<String, Object?>?> getAnalysisByBarcode(String barcode);
}

/// Real HTTP API client that communicates with backend services.
class HttpApiClient implements ApiClient {
  HttpApiClient({required this.baseUrl, required this._secureStorage});

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

  String _messageFromResponseBody(String body, String fallbackMessage) {
    if (body.isEmpty) return fallbackMessage;

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, Object?>) {
        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      // Fall back to the provided generic message.
    }

    return fallbackMessage;
  }

  Never _throwApiError(int? statusCode, String body, String fallbackMessage) {
    throw ApiError(
      _messageFromResponseBody(body, fallbackMessage),
      statusCode: statusCode,
    );
  }

  @override
  Future<Map<String, Object?>> analyze({
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
      if (userId != null && userId.isNotEmpty) {
        request.fields['user_id'] = userId;
      }

      final headers = await _authHeaders();
      request.headers.addAll(headers);

      final response = await request.send().timeout(
        const Duration(seconds: 60),
      );

      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        switch (response.statusCode) {
          case 400:
            _throwApiError(
              response.statusCode,
              body,
              'Ошибка распознавания текста',
            );
          case 502:
            _throwApiError(
              response.statusCode,
              body,
              'Сервис распознавания временно недоступен',
            );
          case 500:
            _throwApiError(
              response.statusCode,
              body,
              'Внутренняя ошибка сервера',
            );
          default:
            _throwApiError(
              response.statusCode,
              body,
              'Не удалось распознать текст',
            );
        }
      }

      final responseBody = await response.stream.bytesToString();
      return jsonDecode(responseBody) as Map<String, Object?>;
    } on ApiError {
      rethrow;
    } catch (e) {
      throw ApiError('Не удалось распознать текст');
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
        _throwApiError(
          response.statusCode,
          response.body,
          'Не удалось получить результат анализа',
        );
      }

      return jsonDecode(response.body) as Map<String, Object?>?;
    } on ApiError {
      rethrow;
    } catch (e) {
      throw ApiError('Не удалось получить результат анализа');
    }
  }
}
