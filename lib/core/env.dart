import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Configuração de ambiente via `--dart-define`.
///
/// Exemplos:
///   flutter run --dart-define=API_URL=http://localhost:3333/v1 --dart-define=FAKE_AUTH=true
///
/// Padrões: no emulador Android, `10.0.2.2` aponta para o host; nos demais,
/// `localhost`. Nunca aponte para produção sem alinhar com a Tecnologia
/// (contexto-prime.md §8 item 11): a API cobra cartão de verdade na Vindi.
class Env {
  Env._();

  static const String _apiUrlDefine = String.fromEnvironment('API_URL');
  static const bool fakeAuth = bool.fromEnvironment('FAKE_AUTH', defaultValue: false);

  /// Nome amigável do aparelho enviado nos logins (`deviceName`).
  static String get deviceName {
    if (kIsWeb) return 'Web';
    try {
      if (Platform.isAndroid) return 'Android';
      if (Platform.isIOS) return 'iOS';
      return Platform.operatingSystem;
    } catch (_) {
      return 'desconhecido';
    }
  }

  /// Plataforma no formato aceito por `RegisterDeviceRequest.platform`.
  /// Fora de iOS/Android devolve `android` apenas para não quebrar o contrato.
  static String get platformCode {
    if (kIsWeb) return 'android';
    try {
      return Platform.isIOS ? 'ios' : 'android';
    } catch (_) {
      return 'android';
    }
  }

  static bool get isAndroid {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  static bool get isIOS {
    if (kIsWeb) return false;
    try {
      return Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  static String get apiUrl {
    if (_apiUrlDefine.isNotEmpty) return _apiUrlDefine;
    if (isAndroid) return 'http://10.0.2.2:3333/v1';
    return 'http://localhost:3333/v1';
  }
}
