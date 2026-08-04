import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/camera/barcode_utils.dart';
import '../../analysis/presentation/analysis_controller.dart';
import '../../auth/presentation/auth_controller.dart';
import '../application/start_scan_session_use_case.dart';
import '../data/scan_repository_impl.dart';
import '../domain/scan_repository.dart';
import '../domain/scan_session.dart';

final scanRepositoryProvider = Provider<ScanRepository>((ref) {
  return ScanRepositoryImpl(
    analysisRepository: ref.watch(analysisRepositoryProvider),
  );
});

final startScanSessionUseCaseProvider = Provider<StartScanSessionUseCase>(
  (ref) => StartScanSessionUseCase(ref.read(scanRepositoryProvider)),
);

final scanControllerProvider =
    AsyncNotifierProvider<ScanController, ScanSession?>(ScanController.new);

class ScanController extends AsyncNotifier<ScanSession?> {
  final Map<String, ScanSession> _sessions = {};

  @override
  Future<ScanSession?> build() async => null;

  ScanSession _trackSession(ScanSession session) {
    _sessions[session.id] = session;
    return session;
  }

  Future<void> scanBarcode(String barcode) async {
    final normalizedBarcode = BarcodeUtils.normalizeRetailBarcode(barcode);
    if (normalizedBarcode == null) {
      state = await _error(ArgumentError('Invalid barcode format.'));
      return;
    }

    final user = ref.read(authControllerProvider).value;
    if (user == null) {
      state = await _error(StateError('User is not authenticated.'));
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await ref
          .read(startScanSessionUseCaseProvider)
          .call(barcode: normalizedBarcode, userId: user.id);
      return _trackSession(session);
    });
  }

  Future<void> scanIngredients({
    required String imagePath,
    required String sessionId,
  }) async {
    final normalizedPath = imagePath.trim();
    if (normalizedPath.isEmpty) {
      state = await _error(ArgumentError('Image path is required.'));
      return;
    }

    final session = _sessions[sessionId];
    if (session == null) {
      state = await _error(StateError('Scan session was not found.'));
      return;
    }

    final user = ref.read(authControllerProvider).value;
    final userId = (user == null || user.isGuest) ? null : user.id;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final updatedSession = await ref
          .read(scanRepositoryProvider)
          .analyzeIngredients(
            session: session,
            userId: userId,
            imagePath: normalizedPath,
          );
      return _trackSession(updatedSession);
    });
  }

  Future<AsyncValue<ScanSession?>> _error(Object error) async {
    return AsyncValue.guard<ScanSession?>(() async => throw error);
  }

  void reset() {
    state = const AsyncData(null);
  }
}
