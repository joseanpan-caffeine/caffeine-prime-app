import 'json.dart';
import 'profile.dart';

class LoginRequest {
  const LoginRequest({required this.email, required this.password, this.deviceName});

  final String email;
  final String password;
  final String? deviceName;

  Json toJson() => compact(<String, dynamic>{
        'email': email,
        'password': password,
        'deviceName': deviceName,
      });
}

class SocialLoginRequest {
  const SocialLoginRequest({required this.idToken, this.fullName, this.deviceName});

  final String idToken;
  final String? fullName;
  final String? deviceName;

  Json toJson() => compact(<String, dynamic>{
        'idToken': idToken,
        'fullName': fullName,
        'deviceName': deviceName,
      });
}

class MagicLinkRequest {
  const MagicLinkRequest({required this.email});

  final String email;

  Json toJson() => <String, dynamic>{'email': email};
}

class MagicLinkExchangeRequest {
  const MagicLinkExchangeRequest({required this.token, this.deviceName});

  final String token;
  final String? deviceName;

  Json toJson() => compact(<String, dynamic>{'token': token, 'deviceName': deviceName});
}

class RefreshRequest {
  const RefreshRequest({required this.refreshToken});

  final String refreshToken;

  Json toJson() => <String, dynamic>{'refreshToken': refreshToken};
}

class RegisterRequest {
  const RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.cpf,
    required this.phone,
    required this.birthDate,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String cpf;
  final String phone;

  /// ISO date (YYYY-MM-DD)
  final String birthDate;

  Json toJson() => <String, dynamic>{
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'cpf': cpf,
        'phone': phone,
        'birthDate': birthDate,
      };
}

class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken, required this.expiresIn});

  final String accessToken;
  final String refreshToken;

  /// segundos
  final int expiresIn;

  factory AuthTokens.fromJson(Json json) => AuthTokens(
        accessToken: asString(json['accessToken']),
        refreshToken: asString(json['refreshToken']),
        expiresIn: asInt(json['expiresIn'], 900),
      );

  Json toJson() => <String, dynamic>{
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiresIn': expiresIn,
      };
}

class AuthResponse {
  const AuthResponse({required this.tokens, required this.user, this.debugToken});

  final AuthTokens tokens;
  final UserProfile user;

  /// Só no modo fake: token do link mágico devolvido pelo BFF para teste.
  final String? debugToken;

  factory AuthResponse.fromJson(Json json) => AuthResponse(
        tokens: AuthTokens.fromJson(json),
        user: UserProfile.fromJson(asMap(json['user']) ?? const <String, dynamic>{}),
        debugToken: asStringOrNull(json['debugToken']),
      );

  Json toJson() => <String, dynamic>{
        ...tokens.toJson(),
        'user': user.toJson(),
        if (debugToken != null) 'debugToken': debugToken,
      };
}

/// Resposta de POST /auth/magic-link (202 `{sent: true}`; no modo fake pode
/// trazer `debugToken`).
class MagicLinkSent {
  const MagicLinkSent({required this.sent, this.debugToken});

  final bool sent;
  final String? debugToken;

  factory MagicLinkSent.fromJson(Json? json) => MagicLinkSent(
        sent: asBool(json?['sent'], true),
        debugToken: asStringOrNull(json?['debugToken'] ?? json?['token']),
      );
}
