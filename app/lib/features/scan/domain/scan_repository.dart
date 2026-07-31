import 'scan_session.dart';

abstract interface class ScanRepository {
  Future<ScanSession> startByBarcode({
    required String barcode,
    required String userId,
  });

  Future<ScanSession> analyzeIngredients({
    required ScanSession session,
    String? userId,
    required String imagePath,
  });
}
