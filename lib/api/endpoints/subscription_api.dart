import '../api_client.dart';
import '../api_error.dart';
import '../models/catalog.dart';
import '../models/common.dart';
import '../models/editing.dart';
import '../models/json.dart';
import '../models/subscription.dart';

/// /me/subscription e /me/catalog.
class SubscriptionApi {
  SubscriptionApi(this._client);

  final ApiClient _client;

  /// Assinatura corrente do cliente (404 → null). Nunca guarde o id.
  Future<Subscription?> current() async {
    try {
      return Subscription.fromJson(await _client.getJson('/me/subscription'));
    } on ApiError catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  Future<Catalog> catalog() async => Catalog.fromJson(await _client.getJson('/me/catalog'));

  Future<PricePreview> preview(PreviewRequest req) async {
    return PricePreview.fromJson(await _client.postJson('/me/subscription/preview', body: req.toJson()));
  }

  /// 403 EDIT_WINDOW_CLOSED; outra `frequency` → id da assinatura muda.
  Future<ScheduledChange> schedule(SchedulingRequest req, {String? idempotencyKey}) async {
    return ScheduledChange.fromJson(
      await _client.postJson('/me/subscription/scheduling', body: req.toJson(), idempotencyKey: idempotencyKey),
    );
  }

  Future<void> cancelScheduling() async => _client.delete('/me/subscription/scheduling');

  /// 422 se todos os itens ficariam 'on'.
  Future<Subscription> setItemRecurrence(String itemId, ItemRecurrence recurrence) async {
    return Subscription.fromJson(
      await _client.patchJson(
        '/me/subscription/items/$itemId/recurrence',
        body: <String, dynamic>{'recurrence': recurrence.wire},
      ),
    );
  }

  Future<Subscription> applyDiscount(String code) async {
    return Subscription.fromJson(
      await _client.patchJson('/me/subscription/discount', body: <String, dynamic>{'code': code}),
    );
  }

  Future<Subscription> pause(PauseRequest req, {String? idempotencyKey}) async {
    return Subscription.fromJson(
      await _client.postJson('/me/subscription/pause', body: req.toJson(), idempotencyKey: idempotencyKey),
    );
  }

  Future<Subscription> resume({String? idempotencyKey}) async {
    return Subscription.fromJson(await _client.postJson('/me/subscription/resume', idempotencyKey: idempotencyKey));
  }

  Future<Subscription> cancel(CancelRequest req, {String? idempotencyKey}) async {
    return Subscription.fromJson(
      await _client.postJson('/me/subscription/cancel', body: req.toJson(), idempotencyKey: idempotencyKey),
    );
  }

  Future<Subscription> reactivate({String? idempotencyKey}) async {
    return Subscription.fromJson(
      await _client.postJson('/me/subscription/reactivate', idempotencyKey: idempotencyKey),
    );
  }

  Future<List<ReasonOption>> cancelReasons() async {
    final List<Json> list = await _client.getList('/me/subscription/cancel-reasons');
    return list.map(ReasonOption.fromJson).toList();
  }

  Future<List<ReasonOption>> pauseReasons() async {
    final List<Json> list = await _client.getList('/me/subscription/pause-reasons');
    return list.map(ReasonOption.fromJson).toList();
  }
}
