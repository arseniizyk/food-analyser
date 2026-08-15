import 'history_item.dart';

abstract interface class HistoryRepository {
  Future<List<HistoryItem>> getHistory(String userId);
}
