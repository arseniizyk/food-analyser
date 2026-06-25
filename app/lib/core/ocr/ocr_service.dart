abstract interface class OcrService {
  Future<String> extractTextFromImage(String imagePath);
}

class MockOcrService implements OcrService {
  @override
  Future<String> extractTextFromImage(String imagePath) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return 'oats, almonds, sugar, cocoa, natural flavor';
  }
}
