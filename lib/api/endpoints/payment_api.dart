import '../api_client.dart';
import '../models/bills.dart';
import '../models/json.dart';
import '../models/payment.dart';
import '../models/subscription.dart';

/// Pagamento: cartões, faturas e config da Vindi.
class PaymentApi {
  PaymentApi(this._client);

  final ApiClient _client;

  Future<VindiConfig> vindiConfig() async {
    return VindiConfig.fromJson(await _client.getJson('/payments/vindi-config', noAuth: true));
  }

  Future<List<PaymentProfile>> paymentProfiles() async {
    final List<Json> list = await _client.getList('/me/payment-profiles');
    return list.map(PaymentProfile.fromJson).toList();
  }

  Future<PaymentProfile> addCard(AddCardRequest req, {String? idempotencyKey}) async {
    return PaymentProfile.fromJson(
      await _client.postJson('/me/payment-profiles', body: req.toJson(), idempotencyKey: idempotencyKey),
    );
  }

  Future<void> removeCard(String id) async => _client.delete('/me/payment-profiles/$id');

  Future<List<Bill>> bills() async {
    final List<Json> list = await _client.getList('/me/bills');
    return list.map(Bill.fromJson).toList();
  }

  Future<Bill> bill(String billId) async => Bill.fromJson(await _client.getJson('/me/bills/$billId'));

  /// Gera (ou regenera) a cobrança PIX. Devolve a fatura com `pix`.
  Future<Bill> payWithPix(String billId, {String? idempotencyKey}) async {
    return Bill.fromJson(await _client.postJson('/me/bills/$billId/pay/pix', idempotencyKey: idempotencyKey));
  }

  Future<Bill> payWithCurrentCard(String billId, {String? idempotencyKey}) async {
    return Bill.fromJson(
      await _client.postJson('/me/bills/$billId/pay/current-card', idempotencyKey: idempotencyKey),
    );
  }

  Future<Bill> payWithNewCard(String billId, PayWithNewCardRequest req, {String? idempotencyKey}) async {
    return Bill.fromJson(
      await _client.postJson('/me/bills/$billId/pay/new-card', body: req.toJson(), idempotencyKey: idempotencyKey),
    );
  }
}
