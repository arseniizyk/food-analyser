import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/history_repository_impl.dart';
import '../domain/history_item.dart';
import '../domain/history_repository.dart';

final remoteHistoryRepositoryProvider = Provider<HistoryRepository>(
  (ref) => RemoteHistoryRepository(ref.read(apiClientProvider)),
);

final localHistoryRepositoryProvider = Provider<HistoryRepository>(
  (ref) => LocalHistoryRepository(ref.read(localStorageProvider)),
);

final historyControllerProvider =
    AsyncNotifierProvider<HistoryController, List<HistoryItem>>(
      HistoryController.new,
    );

class HistoryController extends AsyncNotifier<List<HistoryItem>> {
  @override
  Future<List<HistoryItem>> build() async {
    final user = ref.watch(authControllerProvider).value;
    final repository = (user == null || user.isGuest)
        ? ref.read(localHistoryRepositoryProvider)
        : ref.read(remoteHistoryRepositoryProvider);
    return repository.getHistory(user?.id ?? '');
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
