import 'analysis.dart';

abstract interface class AnalysisRepository {
  Future<Analysis> analyzeProduct({
    required String barcode,
    required String imagePath,
    String? userId,
  });

  Future<Analysis?> getById(String analysisId);
}
