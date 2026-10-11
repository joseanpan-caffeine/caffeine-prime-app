import '../api_client.dart';
import '../models/auth.dart';
import '../models/json.dart';

/// /auth/* — todas sem Bearer.
class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  Future<AuthResponse> login(LoginRequest req) async {
    final Json json = await _client.postJson('/auth/login', body: req.toJson(), noAuth: true);
    return AuthResponse.fromJson(json);
  }

  Future<AuthResponse> google(SocialLoginRequest req) async {
    final Json json = await _client.postJson('/auth/google', body: req.toJson(), noAuth: true);
    return AuthResponse.fromJson(json);
  }

  Future<AuthResponse> apple(SocialLoginRequest req) async {
    final Json json = await _client.postJson('/auth/apple', body: req.toJson(), noAuth: true);
    return AuthResponse.fromJson(json);
  }

  Future<MagicLinkSent> requestMagicLink(MagicLinkRequest req) async {
    final Json json = await _client.postJson('/auth/magic-link', body: req.toJson(), noAuth: true);
    return MagicLinkSent.fromJson(json);
  }

  Future<AuthResponse> exchangeMagicLink(MagicLinkExchangeRequest req) async {
    final Json json = await _client.postJson('/auth/magic-link/exchange', body: req.toJson(), noAuth: true);
    return AuthResponse.fromJson(json);
  }

  Future<AuthResponse> register(RegisterRequest req) async {
    final Json json = await _client.postJson('/auth/register', body: req.toJson(), noAuth: true);
    return AuthResponse.fromJson(json);
  }

  Future<AuthTokens> refresh(RefreshRequest req) async {
    final Json json = await _client.postJson('/auth/refresh', body: req.toJson(), noAuth: true);
    return AuthTokens.fromJson(json);
  }

  Future<void> logout(RefreshRequest req) async {
    await _client.postJson('/auth/logout', body: req.toJson());
  }
}
