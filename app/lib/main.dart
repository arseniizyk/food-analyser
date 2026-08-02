import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/app_providers.dart';
import 'core/storage/hive_local_storage.dart';
import 'core/storage/hive_secure_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final localStorage = HiveLocalStorage.create();
  final secureStorage = HiveSecureStorage.create();

  runApp(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(localStorage),
        secureStorageProvider.overrideWithValue(secureStorage),
      ],
      child: const FoodAnalyzerApp(),
    ),
  );
}
