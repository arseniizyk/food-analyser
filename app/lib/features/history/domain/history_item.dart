class HistoryItem {
  const HistoryItem({
    required this.barcode,
    required this.createdAt,
    required this.score,
  });

  final String barcode;
  final DateTime createdAt;
  final int score;

  factory HistoryItem.fromJson(Map<String, Object?> json) {
    return HistoryItem(
      barcode: json['barcode'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      score: switch (json['score']) {
        final int value => value,
        _ => 0,
      },
    );
  }
}
