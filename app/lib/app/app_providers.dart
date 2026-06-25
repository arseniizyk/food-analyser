import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/camera/barcode_scanner_service.dart';
import '../core/camera/camera_service.dart';
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

final cameraServiceProvider = Provider<CameraService>(
  (ref) => MockCameraService(),
);

final barcodeScannerServiceProvider = Provider<BarcodeScannerService>(
  (ref) => MockBarcodeScannerService(),
);

final ocrServiceProvider = Provider<OcrService>((ref) => MockOcrService());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.read(secureStorageProvider)),
);
