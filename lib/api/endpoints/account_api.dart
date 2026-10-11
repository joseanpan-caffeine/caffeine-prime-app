import '../api_client.dart';
import '../api_error.dart';
import '../models/address.dart';
import '../models/bills.dart';
import '../models/config.dart';
import '../models/dashboard.dart';
import '../models/device.dart';
import '../models/json.dart';
import '../models/profile.dart';
import '../models/subscription.dart';

/// Conta, dashboard, entrega, extras, dispositivo e config.
class AccountApi {
  AccountApi(this._client);

  final ApiClient _client;

  Future<UserProfile> me() async => UserProfile.fromJson(await _client.getJson('/me'));

  Future<UserProfile> updateProfile(UpdateProfileRequest req) async {
    return UserProfile.fromJson(await _client.patchJson('/me/profile', body: req.toJson()));
  }

  Future<Dashboard> dashboard() async => Dashboard.fromJson(await _client.getJson('/me/dashboard'));

  // ---------- Entrega ----------

  Future<ShippingAddress> shippingAddress() async {
    return ShippingAddress.fromJson(await _client.getJson('/me/shipping-address'));
  }

  Future<AddressQuote> quoteAddress(AddressQuoteRequest req) async {
    return AddressQuote.fromJson(await _client.postJson('/me/shipping-address/quote', body: req.toJson()));
  }

  Future<ShippingAddress> updateAddress(UpdateAddressRequest req) async {
    return ShippingAddress.fromJson(await _client.patchJson('/me/shipping-address', body: req.toJson()));
  }

  /// 404 quando não há rastreio → null.
  Future<Fulfillment?> tracking() async {
    try {
      return Fulfillment.fromJson(await _client.getJson('/me/tracking'));
    } on ApiError catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  Future<Savings> savings() async => Savings.fromJson(await _client.getJson('/me/savings'));

  Future<Wallet> wallet() async => Wallet.fromJson(await _client.getJson('/me/wallet'));

  Future<void> requestDeletion({String? reason}) async {
    await _client.postJson('/me/delete-request', body: compact(<String, dynamic>{'reason': reason}));
  }

  // ---------- Dispositivo / preferências ----------

  Future<RegisteredDevice> registerDevice(RegisterDeviceRequest req) async {
    return RegisteredDevice.fromJson(await _client.postJson('/me/devices', body: req.toJson()));
  }

  Future<void> unregisterDevice(String id) async => _client.delete('/me/devices/$id');

  Future<NotificationPreferences> notificationPreferences() async {
    return NotificationPreferences.fromJson(await _client.getJson('/me/notification-preferences'));
  }

  Future<NotificationPreferences> updateNotificationPreferences(Json partial) async {
    return NotificationPreferences.fromJson(await _client.patchJson('/me/notification-preferences', body: partial));
  }

  // ---------- Consentimentos ----------

  /// GET /me/consents: lista ou `{consents: [...]}`.
  Future<List<Consent>> consents() async {
    return _parseConsents(await _client.getRaw('/me/consents'));
  }

  static List<Consent> _parseConsents(dynamic data) {
    if (data is List) return asMapList(data).map(Consent.fromJson).toList();
    final Json? json = asMap(data);
    if (json == null) return <Consent>[];
    if (json.containsKey('kind')) return <Consent>[Consent.fromJson(json)];
    if (json['consents'] is List) return asMapList(json['consents']).map(Consent.fromJson).toList();
    if (json['items'] is List) return asMapList(json['items']).map(Consent.fromJson).toList();
    return <Consent>[];
  }

  /// PUT /me/consents aceita um consentimento; devolve a lista atualizada ou o
  /// item (tratamos os dois formatos).
  Future<List<Consent>> updateConsent(UpdateConsentRequest req) async {
    return _parseConsents(await _client.putRaw('/me/consents', body: req.toJson()));
  }

  // ---------- Config pública ----------

  Future<AppConfig> config() async => AppConfig.fromJson(await _client.getJson('/config', noAuth: true));
}
