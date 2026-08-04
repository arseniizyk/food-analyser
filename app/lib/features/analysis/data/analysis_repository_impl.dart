import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage.dart';
import '../domain/analysis.dart';
import '../domain/analysis_repository.dart';
import 'analysis_dto.dart';

class RemoteAnalysisRepository implements AnalysisRepository {
  const RemoteAnalysisRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<Analysis> analyze({
    required String barcode,
    required String imagePath,
    String? userId,
  }) async {
    final json = await _apiClient.analyze(
      barcode: barcode,
      imagePath: imagePath,
      userId: userId,
    );
    return AnalysisDto.fromJson(json);
  }

  @override
  Future<Analysis?> getByBarcode(String barcode) async {
    final json = await _apiClient.getAnalysisByBarcode(barcode);
    return json == null ? null : AnalysisDto.fromJson(json);
  }
}

class LocalAnalysisRepository implements AnalysisRepository {
  const LocalAnalysisRepository(this._localStorage, this._apiClient);

  final LocalStorage _localStorage;
  final ApiClient _apiClient;

  @override
  Future<Analysis> analyze({
    required String barcode,
    required String imagePath,
    String? userId,
  }) async {
    final json = await _apiClient.analyze(
      barcode: barcode,
      imagePath: imagePath,
      userId: userId,
    );
    final cached = <String, Object?>{
      ...json,
      if (userId != null && userId.isNotEmpty) 'userId': userId,
    };
    await _localStorage.saveAnalysis(cached);
    return AnalysisDto.fromJson(cached);
  }

  @override
  Future<Analysis?> getByBarcode(String barcode) async {
    final json = await _localStorage.getAnalysisByBarcode(barcode);
    return json == null ? null : AnalysisDto.fromJson(json);
  }
}
