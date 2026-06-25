import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/ocr/ocr_service.dart';
import '../core/storage/local_storage.dart';
import '../core/storage/secure_storage.dart';
import '../features/auth/data/auth_repository_impl.dart';
import '../features/auth/domain/auth_repository.dart';

final apiClientProvider = Provider<ApiClient>((ref) => FakeApiClient());

final localStorageProvider = Provider<LocalStorage>(
  (ref) => MemoryLocalStorage(),
);

final secureStorageProvider = Provider<SecureStorage>(
  (ref) => MemorySecureStorage(),
);

final ocrServiceProvider = Provider<OcrService>((ref) {
  if (kIsWeb) {
    return MockOcrService();
  }
  return MlKitOcrService();
});

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.read(secureStorageProvider)),
);
