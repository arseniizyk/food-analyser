import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import 'auth_controller.dart';
import 'login_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return authState.when(
      loading: () => const AppLoadingView(message: 'Checking session...'),
      error: (error, stackTrace) => AppErrorView(
        message: error.toString(),
        onRetry: () => ref.invalidate(authControllerProvider),
      ),
      data: (user) => user == null ? const LoginScreen() : child,
    );
  }
}
