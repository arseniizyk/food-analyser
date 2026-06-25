import '../domain/scan_repository.dart';
import '../domain/scan_session.dart';

class StartScanSessionUseCase {
  const StartScanSessionUseCase(this._scanRepository);

  final ScanRepository _scanRepository;

  Future<ScanSession> call({required String barcode, required String userId}) {
    return _scanRepository.startByBarcode(barcode: barcode, userId: userId);
  }
}
