import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/app_providers.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/hive_local_storage.dart';
import 'core/storage/hive_secure_storage.dart';
import 'core/widgets/app_loading_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final localStorage = HiveLocalStorage.create();
  final secureStorage = HiveSecureStorage.create();

  runApp(
    AppBootstrap(localStorage: localStorage, secureStorage: secureStorage),
  );
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({
    required this.localStorage,
    required this.secureStorage,
    super.key,
  });

  final HiveLocalStorage localStorage;
  final HiveSecureStorage secureStorage;

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late final Future<void> _bootstrapFuture = Future.wait([
    widget.localStorage.warmUp(),
    widget.secureStorage.warmUp(),
  ]);

  ThemeData _bootstrapTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.light,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: colorScheme.surface,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: _bootstrapTheme(),
            home: const _StartupScreen(),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: _bootstrapTheme(),
            home: _StartupErrorScreen(message: snapshot.error.toString()),
          );
        }

        return ProviderScope(
          overrides: [
            localStorageProvider.overrideWithValue(widget.localStorage),
            secureStorageProvider.overrideWithValue(widget.secureStorage),
          ],
          child: const FoodAnalyzerApp(),
        );
      },
    );
  }
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(child: AppLoadingView(message: 'Starting FoodCheck...')),
      ),
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to start app',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
