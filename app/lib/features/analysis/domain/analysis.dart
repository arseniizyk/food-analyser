class Analysis {
  const Analysis({
    required this.id,
    required this.barcode,
    this.userId,
    required this.score,
    required this.grade,
    required this.risks,
    required this.summary,
    required this.createdAt,
    required this.ingredients,
  });

  final String id;
  final String barcode;
  final String? userId;
  final HealthScore score;
  final String grade;
  final List<IngredientRisk> risks;
  final List<String> summary;
  final DateTime createdAt;
  final List<String> ingredients;

  factory Analysis.fromJson(Map<String, Object?> json) {
    return Analysis(
      id: json['id']! as String,
      barcode: json['barcode']! as String,
      userId: json['userId'] as String?,
      score: HealthScore.fromJson(json['score']! as Map<String, Object?>),
      grade: json['grade']! as String,
      risks: (json['risks']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(IngredientRisk.fromJson)
          .toList(),
      summary: (json['summary']! as List<Object?>).cast<String>(),
      createdAt: DateTime.parse(json['createdAt']! as String),
      ingredients: (json['ingredients']! as List<Object?>).cast<String>(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'barcode': barcode,
      'userId': userId,
      'score': score.toJson(),
      'grade': grade,
      'risks': risks.map((risk) => risk.toJson()).toList(),
      'summary': summary,
      'createdAt': createdAt.toIso8601String(),
      'ingredients': ingredients,
    };
  }
}

class HealthScore {
  const HealthScore({required this.value, required this.label});

  final int value;
  final String label;

  factory HealthScore.fromJson(Object? json) {
    if (json is int) {
      return HealthScore(value: json, label: json >= 80 ? 'good' : 'average');
    }

    final map = json as Map<String, Object?>;
    return HealthScore(
      value: map['value']! as int,
      label: map['label']! as String,
    );
  }

  Map<String, Object?> toJson() {
    return {'value': value, 'label': label};
  }
}

class IngredientRisk {
  const IngredientRisk({
    required this.ingredient,
    required this.level,
    required this.reason,
  });

  final String ingredient;
  final RiskLevel level;
  final String reason;

  factory IngredientRisk.fromJson(Map<String, Object?> json) {
    return IngredientRisk(
      ingredient: json['ingredient']! as String,
      level: RiskLevel.values.byName(json['level']! as String),
      reason: json['reason']! as String,
    );
  }

  Map<String, Object?> toJson() {
    return {'ingredient': ingredient, 'level': level.name, 'reason': reason};
  }
}

enum RiskLevel { low, medium, high }
