import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/api_error.dart';
import '../../api/models/common.dart';
import '../../api/models/health.dart';
import '../../core/analytics.dart';
import '../../data/consents_controller.dart';
import '../../data/providers.dart';
import 'device_health_service.dart';
import 'health_service.dart';

final Provider<HealthService> healthServiceProvider = Provider<HealthService>((ref) {
  if (kIsWeb) return NoopHealthService();
  return DeviceHealthService();
});

/// Conecta/desconecta e sincroniza dados de saúde (agregados diários).
/// Ordem obrigatória: consentimento `health_data` → permissão do SO → leitura → POST /me/health/sync.
class HealthController {
  HealthController(this._ref);

  final Ref _ref;
  static const String _kLastSync = 'prime.health.lastSync';

  bool get hasConsent => _ref.read(consentGrantedProvider(ConsentKind.healthData));

  /// Chamado pela tela de consentimento após o aceite explícito.
  Future<bool> connect() async {
    final HealthService service = _ref.read(healthServiceProvider);
    if (!await service.isAvailable()) {
      throw const ApiError(
        code: 'HEALTH_UNAVAILABLE',
        message: 'Dados de saúde não estão disponíveis neste aparelho (precisa de Apple Health ou Health Connect).',
      );
    }
    await _ref.read(consentsControllerProvider).setConsent(ConsentKind.healthData, true);
    final bool granted = await service.requestPermissions();
    if (!granted) {
      // Sem permissão do SO não há dado: mantém o consentimento, mas avisa.
      throw const ApiError(
        code: 'HEALTH_PERMISSION_DENIED',
        message: 'Permissão negada no aparelho. Você pode liberar em Ajustes › Saúde (iOS) ou no Health Connect (Android).',
      );
    }
    _ref.read(analyticsProvider).track(AnalyticsEvents.healthConnect, params: <String, Object?>{'provider': service.provider.wire});
    await sync();
    return true;
  }

  /// Lê 7 dias de agregados e envia. Silencioso quando não há consentimento.
  Future<HealthSummary?> sync({bool force = false}) async {
    if (!hasConsent) return null;
    final HealthService service = _ref.read(healthServiceProvider);
    if (!await service.isAvailable()) return null;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!force) {
      final int last = prefs.getInt(_kLastSync) ?? 0;
      // Evita sincronizar mais de uma vez a cada 30 minutos.
      if (DateTime.now().millisecondsSinceEpoch - last < 30 * 60 * 1000) return null;
    }
    final List<HealthDailySample> samples = await service.readDailyAggregates(days: 7);
    if (samples.isEmpty) return null;
    final HealthSummary summary = await _ref.read(healthApiProvider).sync(HealthSyncRequest(samples: samples));
    await prefs.setInt(_kLastSync, DateTime.now().millisecondsSinceEpoch);
    _ref.read(analyticsProvider).track(AnalyticsEvents.healthSync, params: <String, Object?>{'samples': samples.length});
    _ref.invalidate(healthSummaryProvider);
    return summary;
  }

  /// Revoga o consentimento e para a sincronização. A permissão do SO é
  /// revogada pelo usuário nos ajustes do aparelho (o app não consegue).
  Future<void> disconnect() async {
    await _ref.read(consentsControllerProvider).setConsent(ConsentKind.healthData, false);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLastSync);
    _ref.invalidate(healthSummaryProvider);
  }
}

final Provider<HealthController> healthControllerProvider = Provider<HealthController>((ref) => HealthController(ref));
