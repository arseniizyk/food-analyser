import 'analysis.dart';

abstract interface class AnalysisRepository {
  Future<Analysis> analyze({
    required String barcode,
    required String imagePath,
    String? userId,
  });

  Future<Analysis?> getByBarcode(String barcode);
}
