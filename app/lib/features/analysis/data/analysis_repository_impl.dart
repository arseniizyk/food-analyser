import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage.dart';
import '../domain/analysis.dart';
import '../domain/analysis_repository.dart';
import 'analysis_dto.dart';

class RemoteAnalysisRepository implements AnalysisRepository {
  const RemoteAnalysisRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<Analysis> analyzeProduct({
    required String barcode,
    required String imagePath,
    String? userId,
  }) async {
    final json = await _apiClient.analyzeProduct(
      barcode: barcode,
      imagePath: imagePath,
      userId: userId,
    );
    return AnalysisDto.fromJson(json);
  }

  @override
  Future<Analysis?> getById(String analysisId) async {
    final json = await _apiClient.getAnalysisByBarcode(analysisId);
    return json == null ? null : AnalysisDto.fromJson(json);
  }
}

class LocalAnalysisRepository implements AnalysisRepository {
  const LocalAnalysisRepository(this._localStorage, this._apiClient);

  final LocalStorage _localStorage;
  final ApiClient _apiClient;

  @override
  Future<Analysis> analyzeProduct({
    required String barcode,
    required String imagePath,
    String? userId,
  }) async {
    final json = await _apiClient.analyzeProduct(
      barcode: barcode,
      imagePath: imagePath,
      userId: userId,
    );
    await _localStorage.saveAnalysis(json);
    return AnalysisDto.fromJson(json);
  }

  @override
  Future<Analysis?> getById(String analysisId) async {
    final json = await _localStorage.getAnalysisById(analysisId);
    return json == null ? null : AnalysisDto.fromJson(json);
  }
}
