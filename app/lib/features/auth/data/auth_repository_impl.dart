import 'dart:async';

import '../../../core/storage/secure_storage.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';
import 'google_auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._secureStorage);

  final SecureStorage _secureStorage;
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final StreamController<AppUser?> _userController =
      StreamController.broadcast();

  AppUser? _currentUser;

  @override
  Future<AppUser?> currentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }

    final mode = await _secureStorage.read('auth_mode');
    if (mode == 'guest') {
      _currentUser = const GuestUser('guest-local');
    } else if (mode == 'google') {
      final userId = await _secureStorage.read('user_id') ?? '';
      final email = await _secureStorage.read('email') ?? 'user@example.com';
      final token = await _secureStorage.read('access_token') ?? '';
      _currentUser = AuthorizedUser(
        id: userId,
        email: email,
        accessToken: token,
      );
    }

    return _currentUser;
  }

  @override
  Stream<AppUser?> watchUser() => _userController.stream;

  @override
  Future<AppUser> signInWithGoogle() async {
    final user = await _googleAuthService.signIn();
    _currentUser = user;
    await _secureStorage.write('auth_mode', 'google');
    await _secureStorage.write('user_id', user.id);
    await _secureStorage.write('email', user.email);
    await _secureStorage.write('access_token', user.accessToken);
    _userController.add(user);
    return user;
  }

  @override
  Future<AppUser> continueAsGuest() async {
    const user = GuestUser('guest-local');
    _currentUser = user;
    await _secureStorage.write('auth_mode', 'guest');
    _userController.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    await _secureStorage.delete('auth_mode');
    await _secureStorage.delete('user_id');
    await _secureStorage.delete('email');
    await _secureStorage.delete('access_token');
    _userController.add(null);
  }
}
