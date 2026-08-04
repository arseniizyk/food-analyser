import 'package:app/features/analysis/domain/analysis.dart';
import 'package:app/features/analysis/domain/analysis_repository.dart';
import 'package:app/features/scan/data/scan_repository_impl.dart';
import 'package:app/features/scan/domain/scan_session.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAnalysisRepository implements AnalysisRepository {
  String? lastBarcode;
  String? lastImagePath;
  String? lastUserId;

  @override
  Future<Analysis> analyze({
    required String barcode,
    required String imagePath,
    String? userId,
  }) async {
    lastBarcode = barcode;
    lastImagePath = imagePath;
    lastUserId = userId;
    return Analysis(
      barcode: barcode,
      score: 85,
      grade: GradeLevel.good,
      summary: const [],
      risks: const [],
      ingredients: const [],
    );
  }

  @override
  Future<Analysis?> getByBarcode(String barcode) async => null;
}

ScanSession _session({String? barcode}) {
  return ScanSession(
    id: 'scan-1',
    barcode: barcode,
    ingredientsImagePath: null,
    extractedText: null,
    analysis: null,
    step: ScanStep.checkingAnalysis,
  );
}

void main() {
  test('analyzeIngredients throws without a barcode', () async {
    final analysisRepository = FakeAnalysisRepository();
    final repository = ScanRepositoryImpl(
      analysisRepository: analysisRepository,
    );

    await expectLater(
      repository.analyzeIngredients(
        session: _session(),
        imagePath: 'photo.jpg',
      ),
      throwsStateError,
    );
    expect(analysisRepository.lastBarcode, isNull);
  });

  test(
    'analyzeIngredients delegates analysis with the session barcode',
    () async {
      final analysisRepository = FakeAnalysisRepository();
      final repository = ScanRepositoryImpl(
        analysisRepository: analysisRepository,
      );

      final session = await repository.analyzeIngredients(
        session: _session(barcode: '460000000001'),
        userId: 'user-1',
        imagePath: 'photo.jpg',
      );

      expect(analysisRepository.lastBarcode, '460000000001');
      expect(analysisRepository.lastImagePath, 'photo.jpg');
      expect(analysisRepository.lastUserId, 'user-1');
      expect(session.step, ScanStep.completed);
      expect(session.analysis, isNotNull);
      expect(session.ingredientsImagePath, 'photo.jpg');
    },
  );
}
