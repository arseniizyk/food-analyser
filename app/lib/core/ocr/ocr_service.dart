import 'dart:convert';
import '../network/api_client.dart';

abstract interface class OcrService {
  Future<String> extractTextFromImage(String imagePath);
}

/// Remote OCR service that sends the image to a backend via [ApiClient].
class RemoteOcrService implements OcrService {
  RemoteOcrService(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<String> extractTextFromImage(String imagePath) async {
    try {
      final response = await _apiClient.ocrRecognizeImage(imagePath);
      if (response == null) {
        return '';
      }

      // Parse JSON response from FastAPI server
      // Expected format: {"text": "...", "confidence": 0.9, "lines": [...]}
      try {
        final json = jsonDecode(response) as Map<String, dynamic>;
        final text = json['text'] as String? ?? '';
        return text;
      } catch (e) {
        // If JSON parsing fails, return raw response
        return response;
      }
    } catch (e) {
      throw Exception('OCR service error: $e');
    }
  }
}

class MockOcrService implements OcrService {
  @override
  Future<String> extractTextFromImage(String imagePath) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return 'oats, almonds, sugar, cocoa, natural flavor';
  }
}
