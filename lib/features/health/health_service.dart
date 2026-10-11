import 'package:flutter/foundation.dart';

import '../../api/models/common.dart';
import '../../api/models/health.dart';
import '../../core/formatting.dart';

/// Abstração sobre o acesso a dados de saúde do aparelho (HealthKit / Health
/// Connect). O app lê SÓ AGREGADOS DIÁRIOS dos últimos 7 dias e nunca envia
/// séries brutas (api.ts HealthSyncRequest).
abstract class HealthService {
  /// `false` em web/desktop ou quando o Health Connect não está instalado.
  Future<bool> isAvailable();

  /// Pede permissão de leitura para passos, energia/minutos ativos, treinos e sono.
  Future<bool> requestPermissions();

  Future<bool> hasPermissions();

  /// Agregados diários dos últimos [days] dias (inclui hoje).
  Future<List<HealthDailySample>> readDailyAggregates({int days = 7});

  /// 'apple_health' | 'health_connect' | 'none'
  HealthProvider get provider;
}

/// Implementação vazia (web, desktop, ou quando a plataforma não suporta).
class NoopHealthService implements HealthService {
  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> requestPermissions() async => false;

  @override
  Future<bool> hasPermissions() async => false;

  @override
  Future<List<HealthDailySample>> readDailyAggregates({int days = 7}) async => <HealthDailySample>[];

  @override
  HealthProvider get provider => HealthProvider.none;
}

/// Utilidades puras compartilhadas pelas implementações (testáveis sem plugin).
class HealthAggregation {
  HealthAggregation._();

  /// Lista de dias [YYYY-MM-DD] dos últimos [days] dias, do mais antigo para hoje.
  static List<String> lastDays(int days, {DateTime? now}) {
    final DateTime today = now ?? DateTime.now();
    final DateTime start = DateTime(today.year, today.month, today.day).subtract(Duration(days: days - 1));
    return List<String>.generate(days, (int i) => Fmt.isoDay(start.add(Duration(days: i))));
  }

  /// Soma valores por dia a partir de amostras (date, value).
  static Map<String, double> sumByDay(Iterable<({String date, double value})> samples) {
    final Map<String, double> out = <String, double>{};
    for (final ({String date, double value}) s in samples) {
      out[s.date] = (out[s.date] ?? 0) + s.value;
    }
    return out;
  }

  /// Converte somas diárias em HealthDailySample para uma métrica.
  static List<HealthDailySample> toSamples(HealthMetric metric, Map<String, double> byDay, {String? source}) {
    final List<String> keys = byDay.keys.toList()..sort();
    return keys
        .map((String d) => HealthDailySample(date: d, metric: metric, value: byDay[d]!, source: source))
        .toList();
  }

  static void log(String msg) {
    if (kDebugMode) debugPrint('[health] $msg');
  }
}
