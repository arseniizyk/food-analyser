import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/scan/presentation/barcode_scanner_screen.dart';
import '../features/scan/presentation/ingredients_scan_screen.dart';
import '../features/scan/presentation/ocr_confirmation_screen.dart';
import '../features/scan/presentation/scan_screen.dart';
import 'bottom_nav_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/app/scan',
    redirect: (context, state) {
      final isAuthRoute = state.uri.path == '/auth';

      if (authState.isLoading) {
        return null;
      }

      final user = authState.value;

      if (user == null && !isAuthRoute) {
        return '/auth';
      }

      if (user != null && isAuthRoute) {
        return '/app/scan';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BottomNavShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/scan',
                builder: (context, state) => const ScanScreen(),
                routes: [
                  GoRoute(
                    path: 'barcode',
                    builder: (context, state) => const BarcodeScannerScreen(),
                  ),
                  GoRoute(
                    path: 'ingredients/:sessionId',
                    builder: (context, state) => IngredientCameraScreen(
                      sessionId: state.pathParameters['sessionId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'ocr/:sessionId',
                    builder: (context, state) => OcrConfirmationScreen(
                      sessionId: state.pathParameters['sessionId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/history',
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
