import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../core/config/env.dart';
import '../domain/app_user.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'openid', 'profile'],
  );

  Future<AuthorizedUser> signIn() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw Exception('Google sign-in aborted by user');
    }

    final authentication = await account.authentication;
    final idToken = authentication.idToken;
    final accessToken = authentication.accessToken ?? '';

    if (idToken == null || idToken.isEmpty) {
      throw Exception('Missing id token from Google sign-in');
    }

    final uri = Uri.parse('${Env.apiBaseUrl}/api/v1/auth/google');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_token': idToken}),
    );

    if (resp.statusCode != 200) {
      throw Exception(
        'Backend authentication failed: ${resp.statusCode} ${resp.body}',
      );
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final userId = data['user_id'] as String? ?? '';

    return AuthorizedUser(
      id: userId,
      email: account.email,
      accessToken: accessToken,
    );
  }
}
