import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/env.dart';
import '../core/network/api_client.dart';
import '../core/ocr/ocr_service.dart';
import '../core/storage/local_storage.dart';
import '../core/storage/secure_storage.dart';
import '../features/auth/data/auth_repository_impl.dart';
import '../features/auth/domain/auth_repository.dart';

/// Configuration for API services
const String apiBaseUrl = 'http://localhost:8000'; // Backend API

final apiClientProvider = Provider<ApiClient>((ref) {
  // Use HttpApiClient for production, FakeApiClient for development
  // Change this to HttpApiClient(baseUrl: apiBaseUrl, ocrServiceUrl: ocrServiceUrl)
  // when backend is ready
  return FakeApiClient();
});

final ocrApiClientProvider = Provider<ApiClient>((ref) {
  return HttpApiClient(
    baseUrl: Env.apiBaseUrl,
    ocrServiceUrl: Env.ocrServiceUrl,
  );
});

final localStorageProvider = Provider<LocalStorage>(
  (ref) => MemoryLocalStorage(),
);

final secureStorageProvider = Provider<SecureStorage>(
  (ref) => MemorySecureStorage(),
);

final ocrServiceProvider = Provider<OcrService>((ref) {
  // OCR should be performed on a remote service; provide RemoteOcrService
  final api = ref.read(ocrApiClientProvider);
  return RemoteOcrService(api);
});

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.read(secureStorageProvider)),
);
