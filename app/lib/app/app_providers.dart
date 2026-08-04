import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/env.dart';
import '../core/network/api_client.dart';
import '../core/storage/local_storage.dart';
import '../core/storage/secure_storage.dart';
import '../features/auth/data/auth_repository_impl.dart';
import '../features/auth/domain/auth_repository.dart';

final secureStorageProvider = Provider<SecureStorage>(
  (ref) => MemorySecureStorage(),
);

final apiClientProvider = Provider<ApiClient>((ref) {
  return HttpApiClient(
    baseUrl: Env.apiBaseUrl,
    secureStorage: ref.read(secureStorageProvider),
  );
});

final localStorageProvider = Provider<LocalStorage>(
  (ref) => MemoryLocalStorage(),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repo = AuthRepositoryImpl(ref.read(secureStorageProvider));
  ref.onDispose(repo.dispose);
  return repo;
});
