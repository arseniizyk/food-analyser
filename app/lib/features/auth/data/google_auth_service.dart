import '../domain/app_user.dart';

class GoogleAuthService {
  Future<AuthorizedUser> signIn() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    return const AuthorizedUser(
      id: 'google-user-1',
      email: 'user@example.com',
      accessToken: 'mock-access-token',
    );
  }
}
