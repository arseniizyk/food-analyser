import '../../analysis/domain/analysis.dart';

abstract interface class HistoryRepository {
  Future<List<Analysis>> getHistory(String userId);
}
