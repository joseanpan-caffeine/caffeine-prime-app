import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_error.dart';
import '../api/models/auth.dart';
import '../core/analytics.dart';
import '../core/env.dart';
import '../core/notifications/local_notifications.dart';
import '../core/push/push_provider.dart';
import '../features/auth/social_sign_in.dart';
import 'providers.dart';
import 'session_store.dart';

/// Operações de autenticação. O estado da sessão vive em [SessionStore].
///
/// Modo FAKE_AUTH (BFF com adaptador em memória): o login social envia
/// `idToken = "fake:<email>"` e o link mágico devolve `debugToken`.
class AuthController {
  AuthController(this._ref);

  final Ref _ref;

  SessionStore get _session => _ref.read(sessionProvider.notifier);

  Future<void> _onSignedIn(AuthResponse res) async {
    await _session.setSession(res.tokens, res.user);
    _ref.read(analyticsProvider).setCustomer(res.user.id);
    _ref.read(analyticsProvider).track(AnalyticsEvents.login);
    // Push é opcional e assíncrono: não bloqueia a navegação.
    // ignore: unawaited_futures
    _ref.read(pushRegistrarProvider).registerCurrentToken();
  }

  Future<void> loginWithEmail(String email, String password) async {
    final AuthResponse res = await _ref.read(authApiProvider).login(
          LoginRequest(email: email.trim(), password: password, deviceName: Env.deviceName),
        );
    await _onSignedIn(res);
  }

  /// Login com Google. Em FAKE_AUTH usa `fake:<email>` (sem SDK do Google).
  Future<void> loginWithGoogle({String? fakeEmail}) async {
    final String idToken;
    String? fullName;
    if (Env.fakeAuth) {
      idToken = 'fake:${(fakeEmail ?? 'ativa@teste.com').trim()}';
    } else {
      final SocialCredential cred = await _ref.read(socialSignInProvider).google();
      idToken = cred.idToken;
      fullName = cred.fullName;
    }
    final AuthResponse res = await _ref.read(authApiProvider).google(
          SocialLoginRequest(idToken: idToken, fullName: fullName, deviceName: Env.deviceName),
        );
    await _onSignedIn(res);
  }

  Future<void> loginWithApple({String? fakeEmail}) async {
    final String idToken;
    String? fullName;
    if (Env.fakeAuth) {
      idToken = 'fake:${(fakeEmail ?? 'ativa@teste.com').trim()}';
    } else {
      final SocialCredential cred = await _ref.read(socialSignInProvider).apple();
      idToken = cred.idToken;
      fullName = cred.fullName;
    }
    final AuthResponse res = await _ref.read(authApiProvider).apple(
          SocialLoginRequest(idToken: idToken, fullName: fullName, deviceName: Env.deviceName),
        );
    await _onSignedIn(res);
  }

  Future<MagicLinkSent> requestMagicLink(String email) {
    return _ref.read(authApiProvider).requestMagicLink(MagicLinkRequest(email: email.trim()));
  }

  Future<void> exchangeMagicLink(String token) async {
    final AuthResponse res = await _ref.read(authApiProvider).exchangeMagicLink(
          MagicLinkExchangeRequest(token: token, deviceName: Env.deviceName),
        );
    await _onSignedIn(res);
  }

  Future<void> register(RegisterRequest req) async {
    final AuthResponse res = await _ref.read(authApiProvider).register(req);
    await _onSignedIn(res);
  }

  /// Logout: remove device de push, cancela lembretes locais, revoga o refresh
  /// token no BFF e limpa a sessão. Nunca falha para o usuário.
  Future<void> logout() async {
    _ref.read(analyticsProvider).track(AnalyticsEvents.logout);
    try {
      await _ref.read(pushRegistrarProvider).unregister();
    } catch (_) {}
    try {
      await _ref.read(localNotificationsProvider).cancelAll();
    } catch (_) {}
    final String? refresh = _session.refreshToken;
    if (refresh != null && refresh.isNotEmpty) {
      try {
        await _ref.read(authApiProvider).logout(RefreshRequest(refreshToken: refresh));
      } on ApiError catch (e) {
        debugPrint('logout no BFF falhou: $e');
      } catch (_) {}
    }
    await _session.clear();
    _ref.read(analyticsProvider).setCustomer(null);
  }
}

final Provider<AuthController> authControllerProvider = Provider<AuthController>((ref) => AuthController(ref));

final Provider<SocialSignIn> socialSignInProvider = Provider<SocialSignIn>((ref) {
  // Placeholder: defina o Client ID web do Google via --dart-define ou aqui.
  const String googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  return SocialSignIn(googleWebClientId: googleWebClientId.isEmpty ? null : googleWebClientId);
});
