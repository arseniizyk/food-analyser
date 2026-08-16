import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage.dart';
import '../domain/history_item.dart';
import '../domain/history_repository.dart';

class LocalHistoryRepository implements HistoryRepository {
  const LocalHistoryRepository(this._localStorage);

  final LocalStorage _localStorage;

  @override
  Future<List<HistoryItem>> getHistory(String userId) async {
    final json = await _localStorage.getHistory('');
    return json.map(HistoryItem.fromJson).toList();
  }
}

class RemoteHistoryRepository implements HistoryRepository {
  const RemoteHistoryRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<HistoryItem>> getHistory(String userId) async {
    final json = await _apiClient.getHistory();
    return json.map(HistoryItem.fromJson).toList();
  }
}
