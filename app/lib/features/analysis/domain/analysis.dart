class Analysis {
  const Analysis({
    required this.id,
    required this.productId,
    required this.userId,
    required this.score,
    required this.risks,
    required this.summary,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final String userId;
  final HealthScore score;
  final List<IngredientRisk> risks;
  final List<String> summary;
  final DateTime createdAt;

  factory Analysis.fromJson(Map<String, Object?> json) {
    return Analysis(
      id: json['id']! as String,
      productId: json['productId']! as String,
      userId: json['userId']! as String,
      score: HealthScore.fromJson(json['score']! as Map<String, Object?>),
      risks: (json['risks']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(IngredientRisk.fromJson)
          .toList(),
      summary: (json['summary']! as List<Object?>).cast<String>(),
      createdAt: DateTime.parse(json['createdAt']! as String),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'productId': productId,
      'userId': userId,
      'score': score.toJson(),
      'risks': risks.map((risk) => risk.toJson()).toList(),
      'summary': summary,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class HealthScore {
  const HealthScore({required this.value, required this.label});

  final int value;
  final String label;

  factory HealthScore.fromJson(Map<String, Object?> json) {
    return HealthScore(
      value: json['value']! as int,
      label: json['label']! as String,
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
