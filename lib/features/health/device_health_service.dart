import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import '../../api/models/common.dart';
import '../../api/models/health.dart';
import '../../core/env.dart';
import '../../core/formatting.dart';
import 'health_service.dart';

/// Implementação com o pacote `health` ^11 (HealthKit no iOS, Health Connect no
/// Android).
///
/// VERIFICAR na compilação: este arquivo isola toda a API do pacote `health`
/// (`Health().configure()`, `requestAuthorization(types, permissions:)`,
/// `getHealthDataFromTypes(types:, startTime:, endTime:)`,
/// `getTotalStepsInInterval`, `getHealthConnectSdkStatus`, `HealthValue`).
/// Se algum nome mudou na versão resolvida, o ajuste fica só aqui.
class DeviceHealthService implements HealthService {
  final Health _health = Health();
  bool _configured = false;

  @override
  HealthProvider get provider {
    if (Env.isIOS) return HealthProvider.appleHealth;
    if (Env.isAndroid) return HealthProvider.healthConnect;
    return HealthProvider.none;
  }

  /// Tipos lidos por plataforma (alguns só existem em uma delas).
  List<HealthDataType> get _types {
    if (Env.isIOS) {
      return const <HealthDataType>[
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.EXERCISE_TIME,
        HealthDataType.WORKOUT,
        HealthDataType.SLEEP_ASLEEP,
      ];
    }
    return const <HealthDataType>[
      HealthDataType.STEPS,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.WORKOUT,
      HealthDataType.SLEEP_SESSION,
    ];
  }

  List<HealthDataAccess> get _permissions => _types.map((_) => HealthDataAccess.READ).toList();

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  @override
  Future<bool> isAvailable() async {
    if (kIsWeb || !(Env.isIOS || Env.isAndroid)) return false;
    try {
      await _ensureConfigured();
      if (Env.isAndroid) {
        try {
          final HealthConnectSdkStatus? status = await _health.getHealthConnectSdkStatus();
          return status == HealthConnectSdkStatus.sdkAvailable;
        } catch (e) {
          HealthAggregation.log('getHealthConnectSdkStatus falhou ($e); assumindo disponível');
          return true;
        }
      }
      return true;
    } catch (e) {
      HealthAggregation.log('configure falhou: $e');
      return false;
    }
  }

  @override
  Future<bool> requestPermissions() async {
    if (!await isAvailable()) return false;
    try {
      return await _health.requestAuthorization(_types, permissions: _permissions);
    } catch (e) {
      HealthAggregation.log('requestAuthorization falhou: $e');
      return false;
    }
  }

  @override
  Future<bool> hasPermissions() async {
    if (!await isAvailable()) return false;
    try {
      // No iOS a Apple não revela permissões de leitura: pode voltar null.
      final bool? ok = await _health.hasPermissions(_types, permissions: _permissions);
      return ok ?? Env.isIOS;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<HealthDailySample>> readDailyAggregates({int days = 7}) async {
    if (!await isAvailable()) return <HealthDailySample>[];
    final List<HealthDailySample> out = <HealthDailySample>[];
    final List<String> dayKeys = HealthAggregation.lastDays(days);
    final DateTime now = DateTime.now();
    final DateTime start = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
    final String source = provider.wire;

    // Passos: total por dia (o plugin remove duplicidade entre fontes).
    for (final String key in dayKeys) {
      final DateTime d = DateTime.parse(key);
      final DateTime dayStart = DateTime(d.year, d.month, d.day);
      final DateTime dayEnd = dayStart.add(const Duration(days: 1));
      try {
        final int? steps = await _health.getTotalStepsInInterval(dayStart, dayEnd.isAfter(now) ? now : dayEnd);
        if (steps != null) {
          out.add(HealthDailySample(date: key, metric: HealthMetric.steps, value: steps.toDouble(), source: source));
        }
      } catch (e) {
        HealthAggregation.log('steps $key falhou: $e');
      }
    }

    // Demais tipos: pontos brutos lidos localmente e agregados por dia aqui.
    List<HealthDataPoint> points = <HealthDataPoint>[];
    try {
      final List<HealthDataType> types = _types.where((t) => t != HealthDataType.STEPS).toList();
      points = await _health.getHealthDataFromTypes(types: types, startTime: start, endTime: now);
      points = _health.removeDuplicates(points);
    } catch (e) {
      HealthAggregation.log('getHealthDataFromTypes falhou: $e');
    }

    final Map<String, double> activeMinutes = <String, double>{};
    final Map<String, double> workouts = <String, double>{};
    final Map<String, double> sleepMinutes = <String, double>{};

    for (final HealthDataPoint p in points) {
      final String day = Fmt.isoDay(p.dateTo.toLocal());
      final double durationMin = p.dateTo.difference(p.dateFrom).inSeconds / 60.0;
      switch (p.type) {
        case HealthDataType.EXERCISE_TIME:
          activeMinutes[day] = (activeMinutes[day] ?? 0) + _numeric(p.value);
          break;
        case HealthDataType.WORKOUT:
          workouts[day] = (workouts[day] ?? 0) + 1;
          // Sem EXERCISE_TIME (Android), minutos ativos = duração dos treinos.
          if (!Env.isIOS) activeMinutes[day] = (activeMinutes[day] ?? 0) + durationMin;
          break;
        case HealthDataType.SLEEP_ASLEEP:
        case HealthDataType.SLEEP_SESSION:
          sleepMinutes[day] = (sleepMinutes[day] ?? 0) + durationMin;
          break;
        default:
          break;
      }
    }

    out.addAll(HealthAggregation.toSamples(HealthMetric.activeMinutes, _round(activeMinutes), source: source));
    out.addAll(HealthAggregation.toSamples(HealthMetric.workouts, workouts, source: source));
    out.addAll(HealthAggregation.toSamples(HealthMetric.sleepMinutes, _round(sleepMinutes), source: source));
    return out;
  }

  static double _numeric(HealthValue value) {
    if (value is NumericHealthValue) return value.numericValue.toDouble();
    return 0;
  }

  static Map<String, double> _round(Map<String, double> m) =>
      m.map((String k, double v) => MapEntry<String, double>(k, v.roundToDouble()));
}
