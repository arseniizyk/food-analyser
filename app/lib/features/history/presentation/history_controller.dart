import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../analysis/domain/analysis.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/history_repository_impl.dart';
import '../domain/history_repository.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return LocalHistoryRepository(ref.read(localStorageProvider));
});

final historyControllerProvider =
    AsyncNotifierProvider<HistoryController, List<Analysis>>(
      HistoryController.new,
    );

class HistoryController extends AsyncNotifier<List<Analysis>> {
  @override
  Future<List<Analysis>> build() async {
    final user = ref.watch(authControllerProvider).value;
    if (user == null) {
      return [];
    }

    return ref.read(historyRepositoryProvider).getHistory(user.id);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}
