import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/analysis_repository_impl.dart';
import '../domain/analysis.dart';
import '../domain/analysis_repository.dart';

final analysisRepositoryProvider = Provider<AnalysisRepository>((ref) {
  final user = ref.watch(authControllerProvider).value;
  final apiClient = ref.read(apiClientProvider);

  if (user == null || user.isGuest) {
    return LocalAnalysisRepository(ref.read(localStorageProvider), apiClient);
  }

  return RemoteAnalysisRepository(apiClient);
});

final analysisControllerProvider =
    AsyncNotifierProvider.family<AnalysisController, Analysis?, String>(
      AnalysisController.new,
    );

class AnalysisController extends AsyncNotifier<Analysis?> {
  AnalysisController(this.analysisId);

  final String analysisId;

  @override
  Future<Analysis?> build() {
    return ref.read(analysisRepositoryProvider).getById(analysisId);
  }
}
