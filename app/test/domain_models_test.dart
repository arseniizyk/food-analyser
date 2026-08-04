import 'package:app/features/analysis/data/analysis_dto.dart';
import 'package:app/features/analysis/domain/analysis.dart';
import 'package:app/features/scan/domain/scan_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AnalysisDto round trips a backend-shaped JSON payload', () {
    final json = <String, Object?>{
      'barcode': '460000000001',
      'score': 85,
      'grade': 'good',
      'summary': [
        {'message': 'Composition looks balanced.'},
        {'code': 'balanced_composition', 'message': 'No major risks detected.'},
      ],
      'risks': [
        {
          'severity': 'high',
          'title': 'High sugar',
          'description': 'Contains a significant amount of added sugar.',
        },
      ],
      'ingredients': [
        {'name': 'Sugar', 'risk': 'dangerous'},
        {'name': 'Oats', 'risk': 'safe', 'description': 'Whole grain.'},
      ],
    };

    final analysis = AnalysisDto.fromJson(json);
    final decoded = AnalysisDto.fromJson(AnalysisDto.toJson(analysis));

    expect(decoded.barcode, '460000000001');
    expect(decoded.score, 85);
    expect(decoded.grade, GradeLevel.good);
    expect(decoded.summary, hasLength(2));
    expect(decoded.summary.first.message, 'Composition looks balanced.');
    expect(decoded.summary.last.code, 'balanced_composition');
    expect(decoded.risks, hasLength(1));
    expect(decoded.risks.first.severity, RiskLevel.high);
    expect(decoded.risks.first.title, 'High sugar');
    expect(decoded.ingredients, hasLength(2));
    expect(decoded.ingredients.first.name, 'Sugar');
    expect(decoded.ingredients.first.risk, IngredientRiskLevel.dangerous);
    expect(decoded.ingredients.last.description, 'Whole grain.');
  });

  test('AnalysisDto tolerates missing and malformed fields', () {
    final analysis = AnalysisDto.fromJson(<String, Object?>{'score': 'oops'});

    expect(analysis.barcode, '');
    expect(analysis.score, 0);
    expect(analysis.grade, GradeLevel.average);
    expect(analysis.summary, isEmpty);
    expect(analysis.risks, isEmpty);
    expect(analysis.ingredients, isEmpty);
    expect(analysis.createdAt, isNotNull);
  });

  test('AnalysisDto skips malformed summary, risk and ingredient entries', () {
    final analysis = AnalysisDto.fromJson(<String, Object?>{
      'summary': [
        'plain string',
        {'message': ''},
      ],
      'risks': [
        'plain string',
        {'title': 'Valid risk', 'severity': 'low'},
      ],
      'ingredients': [
        'plain string',
        {'name': 'Valid ingredient', 'risk': 'caution'},
      ],
    });

    expect(analysis.summary, isEmpty);
    expect(analysis.risks, hasLength(1));
    expect(analysis.risks.first.title, 'Valid risk');
    expect(analysis.ingredients, hasLength(1));
    expect(analysis.ingredients.first.risk, IngredientRiskLevel.caution);
  });

  test('ScanSession tracks completed analysis state', () {
    final analysis = Analysis(
      barcode: '460000000001',
      score: 86,
      grade: GradeLevel.good,
      summary: const [SummaryItem(message: 'Composition looks balanced.')],
      risks: const [],
      ingredients: const [
        Ingredient(name: 'Oats', risk: IngredientRiskLevel.safe),
      ],
      createdAt: DateTime(2026, 1, 1),
    );

    final session = ScanSession(
      id: 'scan-1',
      barcode: '460000000001',
      ingredientsImagePath: null,
      extractedText: null,
      analysis: null,
      step: ScanStep.checkingAnalysis,
    ).copyWith(analysis: analysis, step: ScanStep.completed);

    expect(session.analysis, analysis);
    expect(session.step, ScanStep.completed);
  });
}
