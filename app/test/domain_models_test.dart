import 'package:app/features/analysis/domain/analysis.dart';
import 'package:app/features/product/domain/product.dart';
import 'package:app/features/scan/domain/scan_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Product supports JSON round trip', () {
    final product = Product(
      id: 'product-1',
      barcode: '460000000001',
      name: 'Protein Bar',
      brand: 'Green Bite',
      imageUrl: null,
      ingredients: const ['oats', 'almonds', 'sugar'],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 2),
    );

    final decoded = Product.fromJson(product.toJson());

    expect(decoded.id, product.id);
    expect(decoded.ingredients, product.ingredients);
  });

  test('ScanSession tracks completed analysis state', () {
    final analysis = Analysis(
      id: 'analysis-1',
      productId: 'product-1',
      userId: 'guest-local',
      score: const HealthScore(value: 86, label: 'good'),
      risks: const [],
      summary: const ['Composition looks balanced.'],
      createdAt: DateTime(2026, 1, 1),
    );

    final session = ScanSession(
      id: 'scan-1',
      barcode: '460000000001',
      product: null,
      ingredientsImagePath: null,
      extractedText: null,
      analysis: null,
      step: ScanStep.checkingProduct,
    ).copyWith(analysis: analysis, step: ScanStep.completed);

    expect(session.analysis, analysis);
    expect(session.step, ScanStep.completed);
  });
}
