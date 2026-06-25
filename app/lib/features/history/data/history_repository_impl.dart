import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage.dart';
import '../../analysis/data/analysis_dto.dart';
import '../../analysis/domain/analysis.dart';
import '../domain/history_repository.dart';

class RemoteHistoryRepository implements HistoryRepository {
  const RemoteHistoryRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<Analysis>> getHistory(String userId) async {
    final json = await _apiClient.getHistory(userId);
    return json.map(AnalysisDto.fromJson).toList();
  }
}

class LocalHistoryRepository implements HistoryRepository {
  const LocalHistoryRepository(this._localStorage);

  final LocalStorage _localStorage;

  @override
  Future<List<Analysis>> getHistory(String userId) async {
    final json = await _localStorage.getHistory(userId);
    return json.map(AnalysisDto.fromJson).toList();
  }
}
