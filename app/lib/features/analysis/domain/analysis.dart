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
      id: json['id'] as String? ?? '',
      barcode: json['barcode'] as String? ?? '',
      userId: json['userId'] as String?,
      score: HealthScore.fromJson(json['score']),
      grade: json['grade'] as String? ?? 'average',
      risks: _parseRisks(json['risks']),
      summary: _parseSummary(json['summary']),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      ingredients: _parseIngredients(json['ingredients']),
    );
  }

  static List<IngredientRisk> _parseRisks(Object? value) {
    if (value is List) {
      return value
          .whereType<Map<String, Object?>>()
          .map(IngredientRisk.fromJson)
          .toList();
    }
    return [];
  }

  static List<String> _parseSummary(Object? value) {
    if (value is! List) return [];
    final results = <String>[];
    for (final item in value) {
      if (item is String) {
        results.add(item);
      } else if (item is Map<String, Object?>) {
        final message = item['message'] as String?;
        if (message != null && message.isNotEmpty) {
          results.add(message);
        }
      }
    }
    return results;
  }

  static List<String> _parseIngredients(Object? value) {
    if (value is! List) return [];
    final results = <String>[];
    for (final item in value) {
      if (item is String) {
        results.add(item);
      } else if (item is Map<String, Object?>) {
        final name = item['name'] as String?;
        if (name != null && name.isNotEmpty) {
          results.add(name);
        }
      }
    }
    return results;
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

    if (json is Map<String, Object?>) {
      return HealthScore(
        value: json['value'] as int? ?? 0,
        label: json['label'] as String? ?? 'unknown',
      );
    }

    return const HealthScore(value: 0, label: 'unknown');
  }

  Map<String, Object?> toJson() {
    return {'value': value, 'label': label};
  }
}

class IngredientRisk {
  const IngredientRisk({
    required this.title,
    required this.severity,
    required this.description,
  });

  final String title;
  final RiskLevel severity;
  final String description;

  factory IngredientRisk.fromJson(Map<String, Object?> json) {
    return IngredientRisk(
      title: json['title'] as String? ?? 'Unknown',
      severity: _parseRiskLevel(json['severity']),
      description: json['description'] as String? ?? '',
    );
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

  Map<String, Object?> toJson() {
    return {
      'title': title,
      'severity': severity.name,
      'description': description,
    };
  }
}

enum RiskLevel { low, medium, high }
