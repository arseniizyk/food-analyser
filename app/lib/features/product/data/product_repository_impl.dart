import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage.dart';
import '../domain/product.dart';
import '../domain/product_repository.dart';
import 'product_dto.dart';

class RemoteProductRepository implements ProductRepository {
  const RemoteProductRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<Product?> getByBarcode(String barcode) async {
    final json = await _apiClient.getProductByBarcode(barcode);
    return json == null ? null : ProductDto.fromJson(json);
  }

  @override
  Future<Product> createFromIngredients({
    required String barcode,
    required String ingredientsText,
  }) async {
    final json = await _apiClient.createProductFromIngredients(
      barcode: barcode,
      ingredientsText: ingredientsText,
    );
    return ProductDto.fromJson(json);
  }
}

class LocalProductRepository implements ProductRepository {
  const LocalProductRepository(this._localStorage, this._apiClient);

  final LocalStorage _localStorage;
  final ApiClient _apiClient;

  @override
  Future<Product?> getByBarcode(String barcode) async {
    final localJson = await _localStorage.getProductByBarcode(barcode);
    if (localJson != null) {
      return ProductDto.fromJson(localJson);
    }

    final remoteJson = await _apiClient.getProductByBarcode(barcode);
    if (remoteJson == null) {
      return null;
    }

    await _localStorage.saveProduct(remoteJson);
    return ProductDto.fromJson(remoteJson);
  }

  @override
  Future<Product> createFromIngredients({
    required String barcode,
    required String ingredientsText,
  }) async {
    final json = await _apiClient.createProductFromIngredients(
      barcode: barcode,
      ingredientsText: ingredientsText,
    );
    await _localStorage.saveProduct(json);
    return ProductDto.fromJson(json);
  }
}
