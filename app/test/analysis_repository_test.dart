import 'package:app/core/network/api_client.dart';
import 'package:app/core/storage/local_storage.dart';
import 'package:app/features/analysis/data/analysis_repository_impl.dart';
import 'package:app/features/analysis/domain/analysis.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeApiClient implements ApiClient {
  FakeApiClient({this.analysisJson});

  final Map<String, Object?>? analysisJson;
  int lookupCalls = 0;

  @override
  Future<Map<String, Object?>> analyze({
    required String barcode,
    required String imagePath,
    String? userId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, Object?>?> getAnalysisByBarcode(String barcode) async {
    lookupCalls++;
    return analysisJson;
  }
}

void main() {
  final analysisJson = <String, Object?>{
    'barcode': '460000000001',
    'score': 85,
    'grade': 'good',
    'summary': [
      {'message': 'Composition looks balanced.'},
    ],
    'risks': <Object?>[],
    'ingredients': <Object?>[
      {'name': 'Oats', 'risk': 'safe'},
    ],
  };

  test('getByBarcode queries the API and caches the result', () async {
    final apiClient = FakeApiClient(analysisJson: analysisJson);
    final localStorage = MemoryLocalStorage();
    final repository = LocalAnalysisRepository(localStorage, apiClient);

    final analysis = await repository.getByBarcode('460000000001');

    expect(apiClient.lookupCalls, 1);
    expect(analysis, isNotNull);
    expect(analysis!.barcode, '460000000001');
    expect(analysis.score, 85);
    expect(analysis.ingredients.first.name, 'Oats');
    expect(analysis.ingredients.first.risk, IngredientRiskLevel.safe);

    final history = await localStorage.getHistory('');
    expect(history, hasLength(1));
    expect(history.first['barcode'], '460000000001');
  });

  test('getByBarcode returns null when the API has no analysis', () async {
    final apiClient = FakeApiClient(analysisJson: null);
    final localStorage = MemoryLocalStorage();
    final repository = LocalAnalysisRepository(localStorage, apiClient);

    final analysis = await repository.getByBarcode('460000000001');

    expect(apiClient.lookupCalls, 1);
    expect(analysis, isNull);
    expect(await localStorage.getHistory(''), isEmpty);
  });
}
