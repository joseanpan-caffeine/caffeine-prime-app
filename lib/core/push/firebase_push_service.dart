import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../env.dart';
import 'push_service.dart';

/// Push via Firebase Cloud Messaging.
///
/// VERIFICAR na compilação: este arquivo isola toda a API do firebase_core /
/// firebase_messaging. Sem `google-services.json` / `GoogleService-Info.plist`
/// no projeto, `Firebase.initializeApp()` lança e [init] devolve `false` — o app
/// segue com [NoopPushService].
class FirebasePushService implements PushService {
  final StreamController<PushToken> _tokens = StreamController<PushToken>.broadcast();
  final StreamController<Uri> _opened = StreamController<Uri>.broadcast();
  final List<StreamSubscription<dynamic>> _subs = <StreamSubscription<dynamic>>[];
  bool _ready = false;

  String get _provider => Env.isIOS ? 'apns' : 'fcm';

  @override
  Future<bool> init() async {
    if (kIsWeb) return false; // Web exigiria FirebaseOptions e service worker.
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      _subs.add(messaging.onTokenRefresh.listen((String token) {
        _tokens.add(PushToken(token: token, provider: _provider));
      }));
      _subs.add(FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        final Uri? link = deepLinkFromData(message.data);
        if (link != null) _opened.add(link);
      }));
      _ready = true;
      return true;
    } catch (e) {
      debugPrint('Firebase indisponível (push desativado): $e');
      _ready = false;
      return false;
    }
  }

  @override
  Future<PushToken?> getToken() async {
    if (!_ready) return null;
    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      final NotificationSettings settings = await messaging.requestPermission(alert: true, badge: true, sound: true);
      if (settings.authorizationStatus == AuthorizationStatus.denied) return null;
      if (Env.isIOS) {
        // No iOS o token APNs pode demorar; o FCM token depende dele.
        final String? apns = await messaging.getAPNSToken();
        if (apns == null) {
          await Future<void>.delayed(const Duration(seconds: 2));
        }
      }
      final String? token = await messaging.getToken();
      if (token == null || token.isEmpty) return null;
      // Enviamos sempre o token FCM; `provider` indica a plataforma de origem.
      return PushToken(token: token, provider: _provider);
    } catch (e) {
      debugPrint('Falha ao obter token de push: $e');
      return null;
    }
  }

  @override
  Stream<PushToken> get onTokenRefresh => _tokens.stream;

  @override
  Stream<Uri> get onNotificationOpened => _opened.stream;

  @override
  Future<Uri?> initialNotificationLink() async {
    if (!_ready) return null;
    try {
      final RemoteMessage? initial = await FirebaseMessaging.instance.getInitialMessage();
      return deepLinkFromData(initial?.data);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> dispose() async {
    for (final StreamSubscription<dynamic> s in _subs) {
      await s.cancel();
    }
    await _tokens.close();
    await _opened.close();
  }
}
