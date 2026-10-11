import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/models/device.dart';
import '../../data/providers.dart';
import '../env.dart';
import 'firebase_push_service.dart';
import 'push_service.dart';

/// Serviço de push ativo. Começa com Firebase; se não inicializar, Noop.
final Provider<PushService> pushServiceProvider = Provider<PushService>((ref) {
  final PushService service = kIsWeb ? NoopPushService() : FirebasePushService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Registra/atualiza o token de push no BFF (POST /me/devices) quando há
/// sessão e consentimento. Guarda o id do device para o DELETE no logout.
class PushRegistrar {
  PushRegistrar(this._ref);

  final Ref _ref;
  static const String _kDeviceId = 'prime.push.deviceId';
  StreamSubscription<PushToken>? _tokenSub;
  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    final PushService service = _ref.read(pushServiceProvider);
    final bool ok = await service.init();
    if (!ok) return;
    _tokenSub = service.onTokenRefresh.listen((PushToken t) => _register(t));
  }

  /// Chamar após login (e quando o consentimento `push` for concedido).
  Future<void> registerCurrentToken() async {
    await ensureInitialized();
    final PushService service = _ref.read(pushServiceProvider);
    final PushToken? token = await service.getToken();
    if (token != null) await _register(token);
  }

  Future<void> _register(PushToken token) async {
    if (_ref.read(sessionProvider.notifier).user == null) return;
    try {
      String version = '0.0.0';
      try {
        version = (await PackageInfo.fromPlatform()).version;
      } catch (_) {}
      final RegisteredDevice device = await _ref.read(accountApiProvider).registerDevice(
            RegisterDeviceRequest(
              pushToken: token.token,
              pushProvider: token.provider,
              platform: Env.platformCode,
              appVersion: version,
              deviceName: Env.deviceName,
            ),
          );
      if (device.id.isNotEmpty) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kDeviceId, device.id);
      }
    } catch (e) {
      debugPrint('Registro de device falhou: $e');
    }
  }

  /// Chamar antes do logout (ainda com sessão).
  Future<void> unregister() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? id = prefs.getString(_kDeviceId);
      if (id != null && id.isNotEmpty) {
        await _ref.read(accountApiProvider).unregisterDevice(id);
        await prefs.remove(_kDeviceId);
      }
    } catch (e) {
      debugPrint('Remoção de device falhou: $e');
    }
  }

  void dispose() {
    _tokenSub?.cancel();
  }
}

final Provider<PushRegistrar> pushRegistrarProvider = Provider<PushRegistrar>((ref) {
  final PushRegistrar r = PushRegistrar(ref);
  ref.onDispose(r.dispose);
  return r;
});
