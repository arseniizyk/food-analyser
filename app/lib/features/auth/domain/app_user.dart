sealed class AppUser {
  const AppUser();

  String get id;

  bool get isGuest;
}

class GuestUser extends AppUser {
  const GuestUser(this.id);

  @override
  final String id;

  @override
  bool get isGuest => true;
}

class AuthorizedUser extends AppUser {
  const AuthorizedUser({
    required this.id,
    required this.email,
    required this.accessToken,
  });

  @override
  final String id;

  final String email;
  final String accessToken;

  @override
  bool get isGuest => false;
}
