import '../../analysis/domain/analysis.dart';

class ScanSession {
  const ScanSession({
    required this.id,
    required this.barcode,
    required this.ingredientsImagePath,
    required this.extractedText,
    required this.analysis,
    required this.step,
  });

  final String id;
  final String? barcode;
  final String? ingredientsImagePath;
  final String? extractedText;
  final Analysis? analysis;
  final ScanStep step;

  ScanSession copyWith({
    String? id,
    String? barcode,
    String? ingredientsImagePath,
    String? extractedText,
    Analysis? analysis,
    ScanStep? step,
  }) {
    return ScanSession(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      ingredientsImagePath: ingredientsImagePath ?? this.ingredientsImagePath,
      extractedText: extractedText ?? this.extractedText,
      analysis: analysis ?? this.analysis,
      step: step ?? this.step,
    );
  }
}

enum ScanStep {
  checkingAnalysis,
  ingredientsScanning,
  analysisMissing,
  completed,
  failed,
}
