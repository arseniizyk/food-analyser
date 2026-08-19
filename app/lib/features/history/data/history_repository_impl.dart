import 'package:flutter/foundation.dart';

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
    return _parseHistory(json);
  }
}

class RemoteHistoryRepository implements HistoryRepository {
  const RemoteHistoryRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<HistoryItem>> getHistory(String userId) async {
    final json = await _apiClient.getHistory();
    return _parseHistory(json);
  }
}

Future<List<HistoryItem>> _parseHistory(List<Map<String, Object?>> json) {
  return compute(_parseHistoryItems, json);
}

List<HistoryItem> _parseHistoryItems(List<Map<String, Object?>> json) {
  return json.map(HistoryItem.fromJson).toList(growable: false);
}
