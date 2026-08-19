import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/analysis_repository_impl.dart';
import '../domain/analysis.dart';
import '../domain/analysis_repository.dart';

final remoteAnalysisRepositoryProvider = Provider<AnalysisRepository>(
  (ref) => RemoteAnalysisRepository(ref.read(apiClientProvider)),
);

final localAnalysisRepositoryProvider = Provider<AnalysisRepository>(
  (ref) => LocalAnalysisRepository(
    ref.read(localStorageProvider),
    ref.read(apiClientProvider),
  ),
);

AnalysisRepository selectAnalysisRepository(Ref ref) {
  final user = ref.read(authControllerProvider).value;
  if (user == null || user.isGuest) {
    return ref.read(localAnalysisRepositoryProvider);
  }
  return ref.read(remoteAnalysisRepositoryProvider);
}

final analysisControllerProvider =
    AsyncNotifierProvider.family<AnalysisController, Analysis?, String>(
      AnalysisController.new,
    );

class AnalysisController extends AsyncNotifier<Analysis?> {
  AnalysisController(this.barcode);

  final String barcode;

  @override
  Future<Analysis?> build() {
    return selectAnalysisRepository(ref).getByBarcode(barcode);
  }
}
