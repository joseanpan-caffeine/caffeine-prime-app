import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../api/models/routine.dart';
import '../utils/streak.dart';

/// Lembretes locais da rotina (flutter_local_notifications + timezone).
///
/// VERIFICAR na compilação: este arquivo isola a API do
/// flutter_local_notifications v18 (`zonedSchedule` sem
/// `uiLocalNotificationDateInterpretation`, `androidScheduleMode`).
class LocalNotifications {
  LocalNotifications();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final StreamController<String> _taps = StreamController<String>.broadcast();
  bool _initialized = false;
  bool _tzReady = false;

  static const String _channelId = 'routine_reminders';
  static const String _channelName = 'Lembretes da rotina';
  static const String _channelDescription = 'Lembretes para tomar seus produtos Caffeine Army';

  /// Payloads (deep links) de notificações tocadas.
  Stream<String> get onTap => _taps.stream;

  bool get supported => !kIsWeb;

  Future<void> init() async {
    if (_initialized || !supported) return;
    _initialized = true;
    try {
      tzdata.initializeTimeZones();
      _tzReady = true;
    } catch (e) {
      debugPrint('timezone init falhou: $e');
    }
    try {
      const InitializationSettings settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final String? payload = response.payload;
          if (payload != null && payload.isNotEmpty) _taps.add(payload);
        },
      );
    } catch (e) {
      debugPrint('local notifications init falhou: $e');
    }
  }

  /// Pede permissão (Android 13+ e iOS). Devolve true quando concedida ou
  /// quando a plataforma não exige.
  Future<bool> requestPermission() async {
    if (!supported) return false;
    await init();
    try {
      final AndroidFlutterLocalNotificationsPlugin? android =
          _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final bool? granted = await android.requestNotificationsPermission();
        return granted ?? true;
      }
      final IOSFlutterLocalNotificationsPlugin? ios =
          _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final bool? granted = await ios.requestPermissions(alert: true, badge: true, sound: true);
        return granted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('permissão de notificação falhou: $e');
      return false;
    }
  }

  /// Payload que abre a aba Rotina ao tocar.
  Future<void> _getInitialTap() async {
    try {
      final NotificationAppLaunchDetails? details = await _plugin.getNotificationAppLaunchDetails();
      final String? payload = details?.notificationResponse?.payload;
      if (details?.didNotificationLaunchApp == true && payload != null && payload.isNotEmpty) {
        _taps.add(payload);
      }
    } catch (_) {}
  }

  Future<void> emitInitialTap() => _getInitialTap();

  tz.Location _location(String timezone) {
    if (!_tzReady) return tz.UTC;
    try {
      return tz.getLocation(timezone);
    } catch (_) {
      try {
        return tz.getLocation('America/Sao_Paulo');
      } catch (_) {
        return tz.local;
      }
    }
  }

  /// (Re)agenda os lembretes diários de todos os itens do plano. Cancela os
  /// anteriores antes, para refletir mudanças de horário/ativação.
  Future<void> scheduleRoutine(RoutinePlan plan) async {
    if (!supported) return;
    await init();
    await cancelAll();
    final tz.Location loc = _location(plan.timezone);
    for (final RoutineItem item in plan.items) {
      if (!item.reminderEnabled) continue;
      final ({int hour, int minute})? t = StreakHelper.parseHhMm(item.reminderTime ?? item.slot.defaultTime);
      if (t == null) continue;
      final tz.TZDateTime now = tz.TZDateTime.now(loc);
      tz.TZDateTime when = tz.TZDateTime(loc, now.year, now.month, now.day, t.hour, t.minute);
      if (when.isBefore(now)) when = when.add(const Duration(days: 1));
      try {
        await _plugin.zonedSchedule(
          StreakHelper.notificationId(item.id),
          'Hora do seu ${item.title}',
          item.usageHint ?? 'Faça o check-in na sua rotina Prime.',
          when,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDescription,
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          // ignore: deprecated_member_use
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time, // repete diariamente
          payload: 'app://routine?item=${item.id}',
        );
      } catch (e) {
        debugPrint('zonedSchedule falhou para ${item.id}: $e');
      }
    }
  }

  Future<void> cancelAll() async {
    if (!supported) return;
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('cancelAll falhou: $e');
    }
  }

  Future<void> dispose() async {
    await _taps.close();
  }
}

final Provider<LocalNotifications> localNotificationsProvider = Provider<LocalNotifications>((ref) {
  final LocalNotifications n = LocalNotifications();
  ref.onDispose(() => n.dispose());
  return n;
});
