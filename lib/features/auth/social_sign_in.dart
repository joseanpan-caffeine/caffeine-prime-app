import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../api/api_error.dart';

/// Resultado do login social: idToken para o BFF + nome (Apple só manda na 1ª vez).
class SocialCredential {
  const SocialCredential({required this.idToken, this.fullName});

  final String idToken;
  final String? fullName;
}

/// Isola as APIs de google_sign_in 6.x e sign_in_with_apple 6.x.
///
/// VERIFICAR na compilação: `GoogleSignIn().signIn()` / `authentication.idToken`
/// (API da versão 6; a 7 mudou para `GoogleSignIn.instance.authenticate()`), e
/// `SignInWithApple.getAppleIDCredential`.
///
/// Configuração (README): Google exige `serverClientId`/`clientId` web no
/// Android/iOS; Apple exige capability "Sign in with Apple" no Xcode.
class SocialSignIn {
  SocialSignIn({this.googleWebClientId});

  /// Client ID web do Google (necessário para `idToken` na web e, no Android,
  /// como `serverClientId`). Placeholder até configurar o Firebase/Google Cloud.
  final String? googleWebClientId;

  Future<SocialCredential> google() async {
    try {
      final GoogleSignIn signIn = GoogleSignIn(
        scopes: const <String>['email', 'profile'],
        clientId: kIsWeb ? googleWebClientId : null,
        serverClientId: kIsWeb ? null : googleWebClientId,
      );
      final GoogleSignInAccount? account = await signIn.signIn();
      if (account == null) {
        throw const ApiError(code: 'SOCIAL_CANCELLED', message: 'Login cancelado.');
      }
      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const ApiError(
          code: 'SOCIAL_NO_TOKEN',
          message: 'O Google não devolveu o idToken. Confira o Client ID web na configuração.',
        );
      }
      return SocialCredential(idToken: idToken, fullName: account.displayName);
    } on ApiError {
      rethrow;
    } catch (e) {
      throw ApiError(code: 'SOCIAL_GOOGLE_FAILED', message: 'Não foi possível entrar com o Google. ($e)');
    }
  }

  Future<bool> appleAvailable() async {
    if (kIsWeb) return false;
    try {
      return await SignInWithApple.isAvailable();
    } catch (_) {
      return false;
    }
  }

  Future<SocialCredential> apple() async {
    try {
      final AuthorizationCredentialAppleID credential = await SignInWithApple.getAppleIDCredential(
        scopes: <AppleIDAuthorizationScopes>[
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final String? idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw const ApiError(code: 'SOCIAL_NO_TOKEN', message: 'A Apple não devolveu o token de identidade.');
      }
      final String name = '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();
      return SocialCredential(idToken: idToken, fullName: name.isEmpty ? null : name);
    } on ApiError {
      rethrow;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const ApiError(code: 'SOCIAL_CANCELLED', message: 'Login cancelado.');
      }
      throw ApiError(code: 'SOCIAL_APPLE_FAILED', message: 'Não foi possível entrar com a Apple. (${e.message})');
    } catch (e) {
      throw ApiError(code: 'SOCIAL_APPLE_FAILED', message: 'Não foi possível entrar com a Apple. ($e)');
    }
  }
}
