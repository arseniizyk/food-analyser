import 'dart:async';

import 'package:app/app/app_providers.dart';
import 'package:app/features/auth/domain/app_user.dart';
import 'package:app/features/auth/domain/auth_repository.dart';
import 'package:app/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this._user);

  AppUser? _user;
  final StreamController<AppUser?> _controller =
      StreamController.broadcast();

  @override
  Future<AppUser?> currentUser() async => _user;

  @override
  Stream<AppUser?> watchUser() => _controller.stream;

  @override
  Future<AppUser> signInWithGoogle() async => throw UnimplementedError();

  @override
  Future<AppUser> continueAsGuest() async => throw UnimplementedError();

  @override
  Future<void> signOut() async {
    _user = const GuestUser('guest-local');
    _controller.add(_user);
  }

  @override
  void dispose() {
    _controller.close();
  }
}

Widget _buildApp(AppUser user) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository(user)),
    ],
    child: const MaterialApp(home: ProfileScreen()),
  );
}

void main() {
  testWidgets('guest user sees continue with google button', (tester) async {
    await tester.pumpWidget(
      _buildApp(const GuestUser('guest-local')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Signed in as guest'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Sign out'), findsNothing);
  });

  testWidgets('authorized user sees email and sign out button', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        const AuthorizedUser(
          id: 'user-1',
          email: 'user@example.com',
          accessToken: 'jwt-token',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('user@example.com'), findsOneWidget);
    expect(find.text('Signed in with Google'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('Continue with Google'), findsNothing);
  });

  testWidgets('sign out switches to guest view', (tester) async {
    final repo = _FakeAuthRepository(
      const AuthorizedUser(
        id: 'user-1',
        email: 'user@example.com',
        accessToken: 'jwt-token',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Signed in as guest'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Sign out'), findsNothing);
  });
}
