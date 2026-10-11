import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../api/models/common.dart';
import '../../api/models/routine.dart';
import '../../api/models/subscription.dart';
import '../../core/analytics.dart';
import '../../core/formatting.dart';
import '../../core/notifications/local_notifications.dart';
import '../../data/consents_controller.dart';
import '../../data/providers.dart';

/// Ações da rotina: check-in/desfazer, lembretes, meta semanal, onboarding.
/// Exige o consentimento `routine_data` (onboarding) antes de gravar.
class RoutineController {
  RoutineController(this._ref);

  final Ref _ref;

  bool get hasConsent => _ref.read(consentGrantedProvider(ConsentKind.routineData));

  void _requireConsent() {
    if (!hasConsent) {
      throw const ApiError(code: 'CONSENT_REQUIRED', message: 'Ative a rotina para registrar seus check-ins.');
    }
  }

  /// Onboarding: concede `routine_data` e, se o plano estiver vazio, cria um a
  /// partir dos itens da caixa (um item por produto, horário padrão do turno).
  Future<void> enable({required bool withReminders}) async {
    await _ref.read(consentsControllerProvider).setConsent(ConsentKind.routineData, true);
    RoutinePlan plan = await _ref.read(routineApiProvider).plan();
    if (plan.items.isEmpty) {
      final List<RoutineItem> items = <RoutineItem>[];
      final Subscription? sub = await _ref.read(subscriptionProvider.future);
      if (sub != null) {
        for (final ProductItem i in sub.items) {
          if (i.gift) continue;
          final RoutineSlot slot = _slotFor(i.handle);
          items.add(RoutineItem(
            id: 'new-${i.handle}',
            productHandle: i.handle,
            title: i.title,
            imageUrl: i.imageUrl,
            slot: slot,
            reminderTime: slot.defaultTime,
            reminderEnabled: withReminders,
            dosesPerDay: 1,
          ));
        }
      }
      plan = await _ref.read(routineApiProvider).updatePlan(
            UpdateRoutinePlanRequest(items: items, weeklyGoalDays: 5, timezone: 'America/Sao_Paulo'),
          );
    }
    _ref.invalidate(routinePlanProvider);
    _ref.invalidate(routineSummaryProvider);
    if (withReminders) await _rescheduleIfNeeded(plan, requestPermission: true);
  }

  static RoutineSlot _slotFor(String handle) {
    final String h = handle.toLowerCase();
    if (h.contains('morning') || h.contains('shot')) return RoutineSlot.preWorkout;
    if (h.contains('koala') || h.contains('sleep')) return RoutineSlot.evening;
    if (h.contains('whey') || h.contains('protein') || h.contains('creatin')) return RoutineSlot.preWorkout;
    return RoutineSlot.morning;
  }

  Future<void> checkIn(String routineItemId, {CheckInSource source = CheckInSource.manual}) async {
    _requireConsent();
    final String today = Fmt.isoDay(DateTime.now());
    await _ref.read(routineApiProvider).checkIn(CheckInRequest(routineItemId: routineItemId, date: today, source: source));
    _ref.read(analyticsProvider).track(AnalyticsEvents.routineCheckIn, params: <String, Object?>{'item': routineItemId});
    _ref.invalidate(routineSummaryProvider);
  }

  Future<void> undo(String routineItemId) async {
    _requireConsent();
    final String today = Fmt.isoDay(DateTime.now());
    await _ref.read(routineApiProvider).undoCheckIn(CheckInRequest(routineItemId: routineItemId, date: today));
    _ref.read(analyticsProvider).track(AnalyticsEvents.routineUndo, params: <String, Object?>{'item': routineItemId});
    _ref.invalidate(routineSummaryProvider);
  }

  Future<void> updateItem(RoutineItem updated) async {
    _requireConsent();
    final RoutinePlan plan = await _ref.read(routinePlanProvider.future);
    final List<RoutineItem> items = plan.items.map((i) => i.id == updated.id ? updated : i).toList();
    final RoutinePlan saved = await _ref.read(routineApiProvider).updatePlan(UpdateRoutinePlanRequest(items: items));
    _ref.read(analyticsProvider).track(AnalyticsEvents.routineReminderSet, params: <String, Object?>{
      'item': updated.id,
      'enabled': updated.reminderEnabled,
      'time': updated.reminderTime,
    });
    _ref.invalidate(routinePlanProvider);
    await _rescheduleIfNeeded(saved, requestPermission: updated.reminderEnabled);
  }

  Future<void> setWeeklyGoal(int days) async {
    _requireConsent();
    await _ref.read(routineApiProvider).updatePlan(UpdateRoutinePlanRequest(weeklyGoalDays: days.clamp(1, 7).toInt()));
    _ref.invalidate(routinePlanProvider);
    _ref.invalidate(routineSummaryProvider);
  }

  /// Reagenda lembretes locais a partir do plano (chamado também após edição da caixa).
  Future<void> _rescheduleIfNeeded(RoutinePlan plan, {bool requestPermission = false}) async {
    final LocalNotifications local = _ref.read(localNotificationsProvider);
    if (!local.supported) return;
    final bool any = plan.items.any((i) => i.reminderEnabled);
    if (!any) {
      await local.cancelAll();
      return;
    }
    if (requestPermission) {
      final bool ok = await local.requestPermission();
      if (!ok) return;
    }
    await local.scheduleRoutine(plan);
  }

  Future<void> rescheduleFromServer() async {
    try {
      final RoutinePlan plan = await _ref.read(routinePlanProvider.future);
      await _rescheduleIfNeeded(plan);
    } catch (_) {}
  }
}

final Provider<RoutineController> routineControllerProvider = Provider<RoutineController>((ref) => RoutineController(ref));
