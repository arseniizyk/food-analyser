import 'scan_session.dart';

abstract interface class ScanRepository {
  Future<ScanSession> startByBarcode({
    required String barcode,
    required String userId,
  });

  Future<ScanSession> analyzeIngredients({
    required ScanSession session,
    required String userId,
    required String ingredientsText,
  });

  Future<ScanSession> captureIngredients({required ScanSession session});
}
