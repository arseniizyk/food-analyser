import '../../../core/camera/barcode_utils.dart';
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
    final normalized = BarcodeUtils.normalizeRetailBarcode(barcode) ?? barcode;
    final candidates = BarcodeUtils.lookupCandidates(normalized);

    for (final candidate in candidates) {
      final json = await _apiClient.getProductByBarcode(candidate);
      if (json != null) {
        return ProductDto.fromJson(json);
      }
    }

    return null;
  }

  @override
  Future<Product> createFromIngredients({
    required String barcode,
    required String ingredientsText,
  }) async {
    final json = {
      'id': 'product-${DateTime.now().microsecondsSinceEpoch}',
      'barcode': barcode,
      'name': 'Unknown product',
      'brand': null,
      'imageUrl': null,
      'ingredients': ingredientsText
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(),
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    return ProductDto.fromJson(json);
  }
}

class LocalProductRepository implements ProductRepository {
  const LocalProductRepository(this._localStorage, this._apiClient);

  final LocalStorage _localStorage;
  final ApiClient _apiClient;

  @override
  Future<Product?> getByBarcode(String barcode) async {
    final normalized = BarcodeUtils.normalizeRetailBarcode(barcode) ?? barcode;
    final candidates = BarcodeUtils.lookupCandidates(normalized);

    for (final candidate in candidates) {
      final localJson = await _localStorage.getProductByBarcode(candidate);
      if (localJson != null) {
        return ProductDto.fromJson(localJson);
      }

      final remoteJson = await _apiClient.getProductByBarcode(candidate);
      if (remoteJson != null) {
        await _localStorage.saveProduct(remoteJson);
        return ProductDto.fromJson(remoteJson);
      }
    }

    return null;
  }

  @override
  Future<Product> createFromIngredients({
    required String barcode,
    required String ingredientsText,
  }) async {
    final json = {
      'id': 'product-${DateTime.now().microsecondsSinceEpoch}',
      'barcode': barcode,
      'name': 'Unknown product',
      'brand': null,
      'imageUrl': null,
      'ingredients': ingredientsText
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(),
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await _localStorage.saveProduct(json);
    return ProductDto.fromJson(json);
  }
}
