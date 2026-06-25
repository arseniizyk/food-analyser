import 'app_user.dart';

abstract interface class AuthRepository {
  Future<AppUser?> currentUser();

  Stream<AppUser?> watchUser();

  Future<AppUser> signInWithGoogle();

  Future<AppUser> continueAsGuest();

  Future<void> signOut();
}
