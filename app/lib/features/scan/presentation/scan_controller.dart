import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../analysis/presentation/analysis_controller.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../product/data/product_repository_impl.dart';
import '../../product/domain/product_repository.dart';
import '../application/analyze_product_use_case.dart';
import '../application/start_scan_session_use_case.dart';
import '../data/scan_repository_impl.dart';
import '../domain/scan_repository.dart';
import '../domain/scan_session.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final user = ref.watch(authControllerProvider).value;
  final apiClient = ref.read(apiClientProvider);

  if (user == null || user.isGuest) {
    return LocalProductRepository(ref.read(localStorageProvider), apiClient);
  }

  return RemoteProductRepository(apiClient);
});

final scanRepositoryProvider = Provider<ScanRepository>((ref) {
  return ScanRepositoryImpl(
    productRepository: ref.read(productRepositoryProvider),
    analysisRepository: ref.read(analysisRepositoryProvider),
    ocrService: ref.read(ocrServiceProvider),
  );
});

final startScanSessionUseCaseProvider = Provider<StartScanSessionUseCase>(
  (ref) => StartScanSessionUseCase(ref.read(scanRepositoryProvider)),
);

final analyzeProductUseCaseProvider = Provider<AnalyzeProductUseCase>(
  (ref) => AnalyzeProductUseCase(ref.read(scanRepositoryProvider)),
);

final scanControllerProvider =
    AsyncNotifierProvider<ScanController, ScanSession?>(ScanController.new);

class ScanController extends AsyncNotifier<ScanSession?> {
  ScanSession? _lastSession;

  @override
  Future<ScanSession?> build() async => _lastSession;

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
      _lastSession = session;
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
    _lastSession = session;
    state = AsyncData(session);
    return session;
  }

  Future<void> processIngredientsImage(String imagePath) async {
    final normalizedPath = imagePath.trim();
    if (normalizedPath.isEmpty) {
      state = AsyncError(
        ArgumentError('Image path is required.'),
        StackTrace.current,
      );
      return;
    }

    final session = _lastSession;

    if (session == null) {
      state = AsyncError(
        StateError('Scan session is not available.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final updatedSession = await ref
          .read(scanRepositoryProvider)
          .processIngredientsImage(
            session: session,
            imagePath: normalizedPath,
          );
      _lastSession = updatedSession;
      return updatedSession;
    });
  }

  Future<void> analyzeConfirmedIngredients(String ingredientsText) async {
    final normalizedText = ingredientsText.trim();
    if (normalizedText.isEmpty) {
      state = AsyncError(
        ArgumentError('Ingredients text is required.'),
        StackTrace.current,
      );
      return;
    }

    final user = ref.read(authControllerProvider).value;
    final session = _lastSession;

    if (user == null || session == null) {
      state = AsyncError(
        StateError('Scan session is not available.'),
        StackTrace.current,
      );
      return;
    }

    final imagePath = session.ingredientsImagePath;
    if (imagePath == null) {
      state = AsyncError(
        StateError('Image path is required for analysis.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    final userId = user.isGuest ? null : user.id;
    state = await AsyncValue.guard(() async {
      final updatedSession = await ref
          .read(analyzeProductUseCaseProvider)
          .call(
            session: session,
            userId: userId,
            imagePath: imagePath,
            ingredientsText: normalizedText,
          );
      _lastSession = updatedSession;
      return updatedSession;
    });
  }

  void reset() {
    _lastSession = null;
    state = const AsyncData(null);
  }
}
