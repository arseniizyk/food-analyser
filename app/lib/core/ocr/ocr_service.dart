import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

abstract interface class OcrService {
  Future<String> extractTextFromImage(String imagePath);
}

class MlKitOcrService implements OcrService {
  @override
  Future<String> extractTextFromImage(String imagePath) async {
    if (kIsWeb) {
      throw UnsupportedError('On-device OCR is not available on web.');
    }

    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final result = await recognizer.processImage(inputImage);
      return result.text.trim();
    } finally {
      await recognizer.close();
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
