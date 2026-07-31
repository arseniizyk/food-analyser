import '../domain/scan_repository.dart';
import '../domain/scan_session.dart';

class AnalyzeProductUseCase {
  const AnalyzeProductUseCase(this._scanRepository);

  final ScanRepository _scanRepository;

  Future<ScanSession> call({
    required ScanSession session,
    String? userId,
    required String imagePath,
  }) {
    return _scanRepository.analyzeIngredients(
      session: session,
      userId: userId,
      imagePath: imagePath,
    );
  }
}
