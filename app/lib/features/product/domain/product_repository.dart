import 'product.dart';

abstract interface class ProductRepository {
  Future<Product?> getByBarcode(String barcode);

  Future<Product> createFromIngredients({
    required String barcode,
    required String ingredientsText,
  });
}
