class Product {
  const Product({
    required this.id,
    required this.barcode,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.ingredients,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String barcode;
  final String name;
  final String? brand;
  final String? imageUrl;
  final List<String> ingredients;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Product.fromJson(Map<String, Object?> json) {
    return Product(
      id: json['id'] as String? ?? '',
      barcode: json['barcode'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown product',
      brand: json['brand'] as String?,
      imageUrl: json['imageUrl'] as String?,
      ingredients: _parseStringList(json['ingredients']),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static List<String> _parseStringList(Object? value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return [];
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'imageUrl': imageUrl,
      'ingredients': ingredients,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
