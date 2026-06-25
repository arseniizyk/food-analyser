import '../domain/product.dart';

class ProductDto {
  const ProductDto._();

  static Product fromJson(Map<String, Object?> json) => Product.fromJson(json);

  static Map<String, Object?> toJson(Product product) => product.toJson();
}
