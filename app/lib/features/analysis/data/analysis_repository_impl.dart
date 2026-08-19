import 'package:flutter/foundation.dart';

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
    return _parseAnalysis(json);
  }

  @override
  Future<Analysis?> getByBarcode(String barcode) async {
    final json = await _apiClient.getAnalysisByBarcode(barcode);
    return json == null ? null : _parseAnalysis(json);
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
    return _parseAnalysis(cached);
  }

  @override
  Future<Analysis?> getByBarcode(String barcode) async {
    final json = await _apiClient.getAnalysisByBarcode(barcode);
    if (json == null) return null;
    await _localStorage.saveAnalysis(json);
    return _parseAnalysis(json);
  }
}

Future<Analysis> _parseAnalysis(Map<String, Object?> json) {
  return compute(AnalysisDto.fromJson, json);
}
