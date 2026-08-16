import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/env.dart';
import '../domain/app_user.dart';

class GoogleAuthService {
  static const _serverClientId =
      '339737972922-9lc3lnoqjshfvf7tf08qh08a8vcdak5r.apps.googleusercontent.com';
  static const _iosClientId =
      '339737972922-330g7d0blrb8k0db8759a628782j9pa9.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: defaultTargetPlatform == TargetPlatform.iOS ? _iosClientId : null,
    serverClientId: _serverClientId,
  );

  Future<AuthorizedUser> signIn() async {
    try {
      final account = await _googleSignIn.signIn();

      if (account == null) {
        throw Exception('Google sign-in was canceled.');
      }

      final authentication = await account.authentication;
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
        final token = data['access_token'] as String? ?? '';
        final email = (data['email'] as String?) ?? account.email;

        return AuthorizedUser(id: userId, email: email, accessToken: token);
      } catch (e) {
        throw Exception('Failed to authenticate with backend: $e');
      }
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Signing out of Google must never break the local logout.
    }
  }
}
