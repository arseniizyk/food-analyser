import 'package:app/features/analysis/domain/analysis.dart';
import 'package:app/features/analysis/presentation/analysis_controller.dart';
import 'package:app/features/analysis/presentation/analysis_result_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _analysis = Analysis(
  barcode: '460000000001',
  score: 85,
  grade: GradeLevel.good,
  summary: const ['Composition looks balanced.'],
  risks: const [
    Risk(
      title: 'Added sugar',
      severity: RiskLevel.medium,
      description: 'May contribute to excess calories.',
    ),
  ],
  ingredients: [
    for (var i = 0; i < 15; i++)
      Ingredient(
        name: 'Ingredient $i',
        risk: i.isEven
            ? IngredientRiskLevel.safe
            : IngredientRiskLevel.caution,
      ),
  ],
);

class _StubAnalysisController extends AnalysisController {
  _StubAnalysisController(super.barcode);

  @override
  Future<Analysis?> build() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return _analysis;
  }
}

Future<void> _pumpSheet(
  WidgetTester tester, {
  Analysis? initialAnalysis,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: AnalysisResultBottomSheet(
            barcode: _analysis.barcode,
            initialAnalysis: initialAnalysis,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the analysis immediately when it is provided', (
    tester,
  ) async {
    await _pumpSheet(tester, initialAnalysis: _analysis);

    expect(find.text('Analysis result'), findsOneWidget);
    expect(find.text('Barcode 460000000001'), findsOneWidget);
    expect(find.text('85'), findsOneWidget);
    expect(find.text('Health score: 85/100'), findsOneWidget);
    expect(find.text('Composition looks balanced.'), findsOneWidget);
  });

  testWidgets('shows the loading view when no analysis is provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analysisControllerProvider.overrideWith2(
            (arg) => _StubAnalysisController(arg),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AnalysisResultBottomSheet(barcode: _analysis.barcode),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Analyzing product...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('Analysis result'), findsOneWidget);
    expect(find.text('Composition looks balanced.'), findsOneWidget);
  });

  testWidgets('builds ingredient tiles lazily as the list scrolls', (
    tester,
  ) async {
    await _pumpSheet(tester, initialAnalysis: _analysis);

    expect(find.text('Added sugar'), findsOneWidget);

    await tester.tap(find.text('Added sugar'));
    await tester.pumpAndSettle();
    expect(find.text('May contribute to excess calories.'), findsOneWidget);

    expect(find.text('Ingredient 14'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Ingredient 14'),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Ingredient 14'), findsOneWidget);
  });
}