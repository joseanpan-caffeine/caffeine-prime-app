import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models/models.dart';
import '../core/analytics.dart';
import '../core/utils/idempotency.dart';
import 'providers.dart';

/// Ações que escrevem na assinatura. Cada chamada gera uma `Idempotency-Key`
/// própria e, ao terminar, invalida os providers dependentes.
///
/// Nunca guardamos o id da assinatura: todas as rotas são "/me/subscription".
class SubscriptionActions {
  SubscriptionActions(this._ref);

  final Ref _ref;

  Analytics get _analytics => _ref.read(analyticsProvider);

  Future<ScheduledChange> schedule(SchedulingRequest req) async {
    final ScheduledChange result = await _ref.read(subscriptionApiProvider).schedule(req, idempotencyKey: uuidV4());
    _analytics.track(AnalyticsEvents.boxEditConfirm, params: <String, Object?>{
      'items': req.items.length,
      'frequency': req.frequency.wire,
      'nextCycleOnly': req.nextCycleOnly ?? false,
    });
    invalidateSubscriptionData(_ref);
    _ref.invalidate(routinePlanProvider);
    return result;
  }

  Future<void> cancelScheduling() async {
    await _ref.read(subscriptionApiProvider).cancelScheduling();
    _analytics.track(AnalyticsEvents.scheduleCancel);
    invalidateSubscriptionData(_ref);
  }

  Future<Subscription> setItemRecurrence(String itemId, ItemRecurrence recurrence) async {
    final Subscription s = await _ref.read(subscriptionApiProvider).setItemRecurrence(itemId, recurrence);
    invalidateSubscriptionData(_ref);
    return s;
  }

  Future<Subscription> applyDiscount(String code) async {
    final Subscription s = await _ref.read(subscriptionApiProvider).applyDiscount(code);
    invalidateSubscriptionData(_ref);
    return s;
  }

  Future<Subscription> pause(PauseRequest req) async {
    final Subscription s = await _ref.read(subscriptionApiProvider).pause(req, idempotencyKey: uuidV4());
    _analytics.track(AnalyticsEvents.pauseRequest, params: <String, Object?>{'cycles': req.cycles, 'reason': req.reason});
    invalidateSubscriptionData(_ref);
    return s;
  }

  Future<Subscription> resume() async {
    final Subscription s = await _ref.read(subscriptionApiProvider).resume(idempotencyKey: uuidV4());
    _analytics.track(AnalyticsEvents.resumeRequest);
    invalidateSubscriptionData(_ref);
    return s;
  }

  Future<Subscription> cancel(CancelRequest req) async {
    final Subscription s = await _ref.read(subscriptionApiProvider).cancel(req, idempotencyKey: uuidV4());
    _analytics.track(AnalyticsEvents.cancelRequest, params: <String, Object?>{'reason': req.reason});
    invalidateSubscriptionData(_ref);
    return s;
  }

  Future<Subscription> reactivate() async {
    final Subscription s = await _ref.read(subscriptionApiProvider).reactivate(idempotencyKey: uuidV4());
    _analytics.track(AnalyticsEvents.reactivateRequest);
    invalidateSubscriptionData(_ref);
    return s;
  }

  // ---------- Pagamento ----------

  Future<Bill> payWithPix(String billId) async {
    final Bill b = await _ref.read(paymentApiProvider).payWithPix(billId, idempotencyKey: uuidV4());
    _analytics.track(AnalyticsEvents.payPix, params: <String, Object?>{'billId': billId});
    _ref.invalidate(billProvider(billId));
    return b;
  }

  Future<Bill> payWithCurrentCard(String billId) async {
    final Bill b = await _ref.read(paymentApiProvider).payWithCurrentCard(billId, idempotencyKey: uuidV4());
    _analytics.track(AnalyticsEvents.payCurrentCard, params: <String, Object?>{'billId': billId});
    invalidateSubscriptionData(_ref);
    _ref.invalidate(billProvider(billId));
    return b;
  }

  Future<Bill> payWithNewCard(String billId, PayWithNewCardRequest req) async {
    final Bill b = await _ref.read(paymentApiProvider).payWithNewCard(billId, req, idempotencyKey: uuidV4());
    _analytics.track(AnalyticsEvents.payNewCard, params: <String, Object?>{'billId': billId});
    invalidateSubscriptionData(_ref);
    _ref.invalidate(billProvider(billId));
    _ref.invalidate(paymentProfilesProvider);
    return b;
  }

  Future<PaymentProfile> addCard(AddCardRequest req) async {
    final PaymentProfile p = await _ref.read(paymentApiProvider).addCard(req, idempotencyKey: uuidV4());
    _analytics.track(AnalyticsEvents.cardAdd);
    _ref.invalidate(paymentProfilesProvider);
    invalidateSubscriptionData(_ref);
    return p;
  }

  Future<void> removeCard(String id) async {
    await _ref.read(paymentApiProvider).removeCard(id);
    _ref.invalidate(paymentProfilesProvider);
    invalidateSubscriptionData(_ref);
  }

  // ---------- Endereço ----------

  Future<ShippingAddress> updateAddress(UpdateAddressRequest req) async {
    final ShippingAddress a = await _ref.read(accountApiProvider).updateAddress(req);
    _analytics.track(AnalyticsEvents.addressUpdate);
    _ref.invalidate(shippingAddressProvider);
    invalidateSubscriptionData(_ref);
    return a;
  }
}

final Provider<SubscriptionActions> subscriptionActionsProvider =
    Provider<SubscriptionActions>((ref) => SubscriptionActions(ref));
