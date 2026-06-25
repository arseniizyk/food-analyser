import '../domain/scan_repository.dart';
import '../domain/scan_session.dart';

class AnalyzeProductUseCase {
  const AnalyzeProductUseCase(this._scanRepository);

  final ScanRepository _scanRepository;

  Future<ScanSession> call({
    required ScanSession session,
    required String userId,
    required String ingredientsText,
  }) {
    return _scanRepository.analyzeIngredients(
      session: session,
      userId: userId,
      ingredientsText: ingredientsText,
    );
  }
}
