import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/history_repository_impl.dart';
import '../domain/history_item.dart';
import '../domain/history_repository.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final user = ref.watch(authControllerProvider).value;
  if (user == null || user.isGuest) {
    return LocalHistoryRepository(ref.read(localStorageProvider));
  }
  return RemoteHistoryRepository(ref.read(apiClientProvider));
});

final historyControllerProvider =
    AsyncNotifierProvider<HistoryController, List<HistoryItem>>(
      HistoryController.new,
    );

class HistoryController extends AsyncNotifier<List<HistoryItem>> {
  @override
  Future<List<HistoryItem>> build() async {
    final user = ref.watch(authControllerProvider).value;
    return ref.read(historyRepositoryProvider).getHistory(user?.id ?? '');
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  Future<void> refreshSilently() async {
    if (state.isLoading) return;
    final next = await AsyncValue.guard(build);
    if (!next.hasError) {
      state = next;
    }
  }
}
