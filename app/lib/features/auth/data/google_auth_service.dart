import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/env.dart';
import '../domain/app_user.dart';

class GoogleAuthService {
  static const _serverClientId =
      '339737972922-9ecoq5qbv9tgetk8p6duo1dadd9cmcb4.apps.googleusercontent.com';

  Future<AuthorizedUser> signIn() async {
    final googleSignIn = GoogleSignIn.instance;

    await googleSignIn.initialize(serverClientId: _serverClientId);
    await googleSignIn.signOut();

    final account = await googleSignIn.authenticate();
    final authentication = account.authentication;
    final idToken = authentication.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw Exception(
        'Missing id token from Google sign-in. '
        'Make sure google-services.json is properly configured '
        'and the WebClientId matches your Google Cloud Console settings.',
      );
    }

    final uri = Uri.parse('${Env.apiBaseUrl}/api/v1/auth/google');

    try {
      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'id_token': idToken}),
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode != 200) {
        throw Exception(
          'Backend authentication failed: ${resp.statusCode} - ${resp.body}. '
          'Make sure backend is running at $uri and OAUTH_CLIENT_ID is configured.',
        );
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final userId = data['user_id'] as String? ?? '';

      return AuthorizedUser(
        id: userId,
        email: account.email,
        accessToken: '',
      );
    } catch (e) {
      throw Exception('Failed to authenticate with backend: $e');
    }
  }
}
