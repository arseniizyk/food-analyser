import '../../../core/ocr/ocr_service.dart';
import '../../analysis/domain/analysis_repository.dart';
import '../../product/domain/product_repository.dart';
import '../domain/scan_repository.dart';
import '../domain/scan_session.dart';

class ScanRepositoryImpl implements ScanRepository {
  const ScanRepositoryImpl({
    required this.productRepository,
    required this.analysisRepository,
    required this.ocrService,
  });

  final ProductRepository productRepository;
  final AnalysisRepository analysisRepository;
  final OcrService ocrService;

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

    final product = await productRepository.getByBarcode(barcode);
    if (product == null) {
      return session.copyWith(step: ScanStep.productMissing);
    }

    return session.copyWith(
      product: product,
      step: ScanStep.ingredientsScanning,
    );
  }

  @override
  Future<ScanSession> analyzeIngredients({
    required ScanSession session,
    String? userId,
    required String imagePath,
    required String ingredientsText,
  }) async {
    final product = await productRepository.createFromIngredients(
      barcode: session.barcode ?? 'manual-${session.id}',
      ingredientsText: ingredientsText,
    );
    final analysis = await analysisRepository.analyzeProduct(
      barcode: product.barcode,
      imagePath: imagePath,
      userId: userId,
    );

    return session.copyWith(
      product: product,
      extractedText: ingredientsText,
      analysis: analysis,
      step: ScanStep.completed,
    );
  }

  @override
  Future<ScanSession> processIngredientsImage({
    required ScanSession session,
    required String imagePath,
  }) async {
    final extractedText = await ocrService.extractTextFromImage(imagePath);

    return session.copyWith(
      ingredientsImagePath: imagePath,
      extractedText: extractedText,
      step: ScanStep.ocrReview,
    );
  }
}
