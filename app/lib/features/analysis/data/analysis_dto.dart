import '../domain/analysis.dart';

class AnalysisDto {
  const AnalysisDto._();

  static Analysis fromJson(Map<String, Object?> json) {
    return Analysis(
      barcode: json['barcode'] as String? ?? '',
      score: switch (json['score']) {
        final int value => value,
        _ => 0,
      },
      grade: _parseGrade(json['grade']),
      summary: _parseSummary(json['summary']),
      risks: _parseRisks(json['risks']),
      ingredients: _parseIngredients(json['ingredients']),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  static Map<String, Object?> toJson(Analysis analysis) {
    return {
      'barcode': analysis.barcode,
      'score': analysis.score,
      'grade': analysis.grade.name,
      'summary': analysis.summary
          .map(
            (item) => {
              'message': item.message,
              if (item.code != null) 'code': item.code,
            },
          )
          .toList(),
      'risks': analysis.risks
          .map(
            (risk) => {
              'severity': risk.severity.name,
              'title': risk.title,
              'description': risk.description,
            },
          )
          .toList(),
      'ingredients': analysis.ingredients
          .map(
            (ingredient) => {
              'name': ingredient.name,
              'risk': ingredient.risk.name,
              if (ingredient.description != null)
                'description': ingredient.description,
            },
          )
          .toList(),
      'createdAt': (analysis.createdAt ?? DateTime.now()).toIso8601String(),
    };
  }

  static GradeLevel _parseGrade(Object? value) {
    if (value is String) {
      return GradeLevel.values.firstWhere(
        (e) => e.name == value,
        orElse: () => GradeLevel.average,
      );
    }
    return GradeLevel.average;
  }

  static List<SummaryItem> _parseSummary(Object? value) {
    if (value is! List) return [];
    final results = <SummaryItem>[];
    for (final item in value) {
      if (item is Map<String, Object?>) {
        final message = item['message'] as String?;
        if (message != null && message.isNotEmpty) {
          results.add(
            SummaryItem(message: message, code: item['code'] as String?),
          );
        }
      }
    }
    return results;
  }

  static List<Risk> _parseRisks(Object? value) {
    if (value is! List) return [];
    final results = <Risk>[];
    for (final item in value) {
      if (item is Map<String, Object?>) {
        final title = item['title'] as String?;
        if (title == null || title.isEmpty) continue;
        results.add(
          Risk(
            title: title,
            severity: _parseRiskLevel(item['severity']),
            description: item['description'] as String? ?? '',
          ),
        );
      }
    }
    return results;
  }

  static RiskLevel _parseRiskLevel(Object? value) {
    if (value is String) {
      return RiskLevel.values.firstWhere(
        (e) => e.name == value,
        orElse: () => RiskLevel.low,
      );
    }
    return RiskLevel.low;
  }

  static List<Ingredient> _parseIngredients(Object? value) {
    if (value is! List) return [];
    final results = <Ingredient>[];
    for (final item in value) {
      if (item is Map<String, Object?>) {
        final name = item['name'] as String?;
        if (name == null || name.isEmpty) continue;
        results.add(
          Ingredient(
            name: name,
            risk: _parseIngredientRiskLevel(item['risk']),
            description: item['description'] as String?,
          ),
        );
      }
    }
    return results;
  }

  static IngredientRiskLevel _parseIngredientRiskLevel(Object? value) {
    if (value is String) {
      return IngredientRiskLevel.values.firstWhere(
        (e) => e.name == value,
        orElse: () => IngredientRiskLevel.safe,
      );
    }
    return IngredientRiskLevel.safe;
  }
}
