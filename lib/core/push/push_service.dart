import 'dart:async';

/// Abstração de push. O app não depende diretamente do Firebase: quando o
/// Firebase não está configurado em runtime (sem google-services.json /
/// GoogleService-Info.plist), usa-se [NoopPushService].
abstract class PushService {
  /// Inicializa o provedor. Devolve `false` quando push não está disponível.
  Future<bool> init();

  /// Pede permissão e devolve o token de push (FCM/APNs) ou null.
  Future<PushToken?> getToken();

  /// Emite novos tokens (rotação).
  Stream<PushToken> get onTokenRefresh;

  /// Deep links vindos de toque em notificação (app aberto ou em background)
  /// e da notificação que abriu o app (cold start).
  Stream<Uri> get onNotificationOpened;

  /// Deep link da notificação que abriu o app, se houver.
  Future<Uri?> initialNotificationLink();

  Future<void> dispose();
}

class PushToken {
  const PushToken({required this.token, required this.provider});

  final String token;

  /// 'fcm' | 'apns'
  final String provider;
}

/// Implementação vazia: push desativado.
class NoopPushService implements PushService {
  final StreamController<PushToken> _tokens = StreamController<PushToken>.broadcast();
  final StreamController<Uri> _opened = StreamController<Uri>.broadcast();

  @override
  Future<bool> init() async => false;

  @override
  Future<PushToken?> getToken() async => null;

  @override
  Stream<PushToken> get onTokenRefresh => _tokens.stream;

  @override
  Stream<Uri> get onNotificationOpened => _opened.stream;

  @override
  Future<Uri?> initialNotificationLink() async => null;

  @override
  Future<void> dispose() async {
    await _tokens.close();
    await _opened.close();
  }
}

/// Extrai o deep link de um payload de notificação (`data.deepLink`,
/// `data.link` ou `data.url`).
Uri? deepLinkFromData(Map<String, dynamic>? data) {
  if (data == null) return null;
  final Object? raw = data['deepLink'] ?? data['deep_link'] ?? data['link'] ?? data['url'];
  if (raw is! String || raw.isEmpty) return null;
  return Uri.tryParse(raw);
}
