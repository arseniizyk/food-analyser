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
      ingredientsImagePath: null,
      extractedText: null,
      analysis: null,
      step: ScanStep.checkingAnalysis,
    );

    final analysis = await analysisRepository.getByBarcode(barcode);
    if (analysis != null) {
      return session.copyWith(analysis: analysis, step: ScanStep.completed);
    }

    return session.copyWith(step: ScanStep.analysisMissing);
  }

  @override
  Future<ScanSession> analyzeIngredients({
    required ScanSession session,
    String? userId,
    required String imagePath,
  }) async {
    final barcode = session.barcode;
    if (barcode == null || barcode.isEmpty) {
      throw StateError('Cannot analyze ingredients without a barcode.');
    }

    final analysis = await analysisRepository.analyze(
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
