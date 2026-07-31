import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  @override
  Future<ScanSession?> build() async => null;

  Future<void> scanBarcode(String barcode) async {
    final normalizedBarcode = barcode.trim();
    if (normalizedBarcode.isEmpty) {
      state = AsyncError(
        ArgumentError('Barcode is required.'),
        StackTrace.current,
      );
      return;
    }

    final user = ref.read(authControllerProvider).value;
    if (user == null) {
      state = AsyncError(
        StateError('User is not authenticated.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await ref
          .read(startScanSessionUseCaseProvider)
          .call(barcode: normalizedBarcode, userId: user.id);
      return session;
    });
  }

  Future<ScanSession> startIngredientSession({String? barcode}) async {
    final session = ScanSession(
      id: 'scan-${DateTime.now().microsecondsSinceEpoch}',
      barcode: barcode,
      product: null,
      ingredientsImagePath: null,
      extractedText: null,
      analysis: null,
      step: ScanStep.ingredientsScanning,
    );
    state = AsyncData(session);
    return session;
  }

  Future<void> scanIngredients({
    required String imagePath,
    String? sessionId,
  }) async {
    final normalizedPath = imagePath.trim();
    if (normalizedPath.isEmpty) {
      state = AsyncError(
        ArgumentError('Image path is required.'),
        StackTrace.current,
      );
      return;
    }

    var session = state.value ?? await startIngredientSession();

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
      return updatedSession;
    });
  }

  void reset() {
    state = const AsyncData(null);
  }
}
