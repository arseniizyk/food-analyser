import 'package:app/core/storage/secure_storage.dart';
import 'package:app/features/auth/data/auth_repository_impl.dart';
import 'package:app/features/auth/data/google_auth_service.dart';
import 'package:app/features/auth/domain/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGoogleAuthService extends GoogleAuthService {
  bool signOutCalled = false;

  @override
  Future<AuthorizedUser> signIn() async {
    return const AuthorizedUser(
      id: 'user-1',
      email: 'user@example.com',
      accessToken: 'jwt-token',
    );
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }
}

void main() {
  test('signInWithGoogle persists access token', () async {
    final storage = MemorySecureStorage();
    final repo = AuthRepositoryImpl(storage, _FakeGoogleAuthService());

    final user = await repo.signInWithGoogle();

    expect((user as AuthorizedUser).accessToken, 'jwt-token');
    expect(await storage.read('auth_mode'), 'google');
    expect(await storage.read('user_id'), 'user-1');
    expect(await storage.read('email'), 'user@example.com');
    expect(await storage.read('access_token'), 'jwt-token');
  });

  test('signOut turns user into guest and clears credentials', () async {
    final storage = MemorySecureStorage();
    final google = _FakeGoogleAuthService();
    final repo = AuthRepositoryImpl(storage, google);

    await repo.signInWithGoogle();
    expect((await repo.currentUser()), isA<AuthorizedUser>());

    await repo.signOut();

    expect(google.signOutCalled, isTrue);
    final user = await repo.currentUser();
    expect(user, isA<GuestUser>());
    expect(user!.isGuest, isTrue);
    expect((user as GuestUser).id, 'guest-local');
    expect(await storage.read('auth_mode'), 'guest');
    expect(await storage.read('user_id'), isNull);
    expect(await storage.read('email'), isNull);
    expect(await storage.read('access_token'), isNull);
  });

  test('signOut restores guest session after app restart', () async {
    final storage = MemorySecureStorage();
    final repo = AuthRepositoryImpl(storage, _FakeGoogleAuthService());

    await repo.signInWithGoogle();
    await repo.signOut();

    final restored = await AuthRepositoryImpl(storage).currentUser();
    expect(restored, isA<GuestUser>());
    expect(restored!.isGuest, isTrue);
  });
}
