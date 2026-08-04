class Analysis {
  const Analysis({
    required this.barcode,
    required this.score,
    required this.grade,
    required this.summary,
    required this.risks,
    required this.ingredients,
    this.createdAt,
  });

  final String barcode;
  final int score;
  final GradeLevel grade;
  final List<SummaryItem> summary;
  final List<Risk> risks;
  final List<Ingredient> ingredients;

  /// Local-only timestamp used for history sorting and display.
  /// Not part of the backend response; defaults to the moment of parsing.
  final DateTime? createdAt;
}

class SummaryItem {
  const SummaryItem({required this.message, this.code});

  final String message;
  final String? code;
}

class Risk {
  const Risk({
    required this.title,
    required this.severity,
    required this.description,
  });

  final String title;
  final RiskLevel severity;
  final String description;
}

enum RiskLevel { low, medium, high }

class Ingredient {
  const Ingredient({required this.name, required this.risk, this.description});

  final String name;
  final IngredientRiskLevel risk;
  final String? description;
}

enum IngredientRiskLevel { safe, caution, dangerous }

enum GradeLevel { excellent, good, average, poor }
