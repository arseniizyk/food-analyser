import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../domain/app_user.dart';
import '../domain/auth_exceptions.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, AppUser?>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AppUser?> {
  final StreamController<String> _notices = StreamController.broadcast();
  Stream<String> get notices => _notices.stream;

  @override
  Future<AppUser?> build() async {
    final repository = ref.read(authRepositoryProvider);
    final subscription = repository.watchUser().listen((user) {
      state = AsyncData(user);
    });

    ref.onDispose(() {
      unawaited(subscription.cancel());
      unawaited(_notices.close());
    });

    return repository.currentUser();
  }

  Future<void> signInWithGoogle() async {
    final previous = state;
    state = const AsyncLoading();
    try {
      final user = await ref.read(authRepositoryProvider).signInWithGoogle();
      state = AsyncData<AppUser?>(user);
    } on GoogleSignInCanceledException {
      state = previous;
      _notices.add('Sign-in canceled.');
    } catch (e) {
      state = AsyncError<AppUser?>(e, StackTrace.current);
      _notices.add('Sign-in failed. Please try again.');
    }
  }

  Future<void> continueAsGuest() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).continueAsGuest(),
    );
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signOut();
      return ref.read(authRepositoryProvider).currentUser();
    });
  }
}
