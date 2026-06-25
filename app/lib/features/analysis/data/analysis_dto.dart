import '../domain/analysis.dart';

class AnalysisDto {
  const AnalysisDto._();

  static Analysis fromJson(Map<String, Object?> json) =>
      Analysis.fromJson(json);

  static Map<String, Object?> toJson(Analysis analysis) => analysis.toJson();
}
