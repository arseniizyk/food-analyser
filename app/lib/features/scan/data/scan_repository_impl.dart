import '../../analysis/domain/analysis_repository.dart';
import '../domain/scan_repository.dart';
import '../domain/scan_session.dart';

class ScanRepositoryImpl implements ScanRepository {
  const ScanRepositoryImpl({required this.analysisRepository});

  final AnalysisRepository analysisRepository;

  @override
  Future<ScanSession> startByBarcode({
    required String barcode,
    required String userId,
  }) async {
    final session = ScanSession(
      id: 'scan-${DateTime.now().microsecondsSinceEpoch}',
      barcode: barcode,
      product: null,
      ingredientsImagePath: null,
      extractedText: null,
      analysis: null,
      step: ScanStep.checkingProduct,
    );

    final analysis = await analysisRepository.getById(barcode);
    if (analysis != null) {
      return session.copyWith(analysis: analysis, step: ScanStep.completed);
    }

    return session.copyWith(step: ScanStep.productMissing);
  }

  @override
  Future<ScanSession> analyzeIngredients({
    required ScanSession session,
    String? userId,
    required String imagePath,
  }) async {
    final barcode = session.barcode ?? 'manual-${session.id}';
    final analysis = await analysisRepository.analyzeProduct(
      barcode: barcode,
      imagePath: imagePath,
      userId: userId,
    );

    return session.copyWith(
      ingredientsImagePath: imagePath,
      analysis: analysis,
      step: ScanStep.completed,
    );
  }
}
