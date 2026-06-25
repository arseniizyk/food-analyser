import '../../product/domain/product.dart';
import 'analysis.dart';

abstract interface class AnalysisRepository {
  Future<Analysis> analyzeProduct({
    required Product product,
    required String userId,
    required String ingredientsText,
  });

  Future<Analysis?> getById(String analysisId);
}
