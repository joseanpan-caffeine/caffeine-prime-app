import 'common.dart';
import 'json.dart';
import 'subscription.dart';

class TrackingEvent {
  const TrackingEvent({required this.status, required this.description, required this.occurredAt, this.location});

  final String status;
  final String description;
  final String occurredAt;
  final String? location;

  factory TrackingEvent.fromJson(Json json) => TrackingEvent(
        status: asString(json['status']),
        description: asString(json['description']),
        occurredAt: asString(json['occurredAt']),
        location: asStringOrNull(json['location']),
      );

  Json toJson() => compact(<String, dynamic>{
        'status': status,
        'description': description,
        'occurredAt': occurredAt,
        'location': location,
      });
}

class Fulfillment {
  const Fulfillment({
    required this.status,
    this.carrier,
    this.trackingCode,
    this.trackingUrl,
    this.estimatedDeliveryAt,
    required this.events,
  });

  final FulfillmentStatus status;
  final String? carrier;
  final String? trackingCode;
  final String? trackingUrl;
  final String? estimatedDeliveryAt;
  final List<TrackingEvent> events;

  factory Fulfillment.fromJson(Json json) => Fulfillment(
        status: FulfillmentStatus.parse(json['status']),
        carrier: asStringOrNull(json['carrier']),
        trackingCode: asStringOrNull(json['trackingCode']),
        trackingUrl: asStringOrNull(json['trackingUrl']),
        estimatedDeliveryAt: asStringOrNull(json['estimatedDeliveryAt']),
        events: asMapList(json['events']).map(TrackingEvent.fromJson).toList(),
      );

  Json toJson() => compact(<String, dynamic>{
        'status': status.wire,
        'carrier': carrier,
        'trackingCode': trackingCode,
        'trackingUrl': trackingUrl,
        'estimatedDeliveryAt': estimatedDeliveryAt,
        'events': events.map((e) => e.toJson()).toList(),
      });
}

class PixCharge {
  const PixCharge({required this.qrCodeImageUrl, required this.qrCodeText, required this.expiresAt});

  final String qrCodeImageUrl;

  /// copia e cola
  final String qrCodeText;
  final String expiresAt;

  factory PixCharge.fromJson(Json json) => PixCharge(
        qrCodeImageUrl: asString(json['qrCodeImageUrl']),
        qrCodeText: asString(json['qrCodeText']),
        expiresAt: asString(json['expiresAt']),
      );

  Json toJson() => <String, dynamic>{
        'qrCodeImageUrl': qrCodeImageUrl,
        'qrCodeText': qrCodeText,
        'expiresAt': expiresAt,
      };
}

class Bill {
  const Bill({
    required this.id,
    required this.cycle,
    required this.status,
    required this.issuedAt,
    required this.dueAt,
    this.paidAt,
    required this.amount,
    this.paymentMethod,
    this.paymentProfile,
    this.pix,
    required this.items,
    this.fulfillment,
    this.pausedCycle,
  });

  final String id;
  final int cycle;
  final BillStatus status;
  final String issuedAt;
  final String dueAt;
  final String? paidAt;
  final Money amount;
  final PaymentMethod? paymentMethod;
  final PaymentProfile? paymentProfile;

  /// presente se há cobrança PIX pendente
  final PixCharge? pix;
  final List<ProductItem> items;
  final Fulfillment? fulfillment;

  /// Fatura de ciclo pausado (R$ 0,00): esperado, não é erro (§5.3).
  final bool? pausedCycle;

  bool get isPausedCycle => pausedCycle ?? false;

  factory Bill.fromJson(Json json) => Bill(
        id: asString(json['id']),
        cycle: asInt(json['cycle']),
        status: BillStatus.parse(json['status']),
        issuedAt: asString(json['issuedAt']),
        dueAt: asString(json['dueAt']),
        paidAt: asStringOrNull(json['paidAt']),
        amount: Money.fromJson(asMap(json['amount'])),
        paymentMethod: PaymentMethod.parseOrNull(json['paymentMethod']),
        paymentProfile: asMap(json['paymentProfile']) == null ? null : PaymentProfile.fromJson(asMap(json['paymentProfile'])!),
        pix: asMap(json['pix']) == null ? null : PixCharge.fromJson(asMap(json['pix'])!),
        items: asMapList(json['items']).map(ProductItem.fromJson).toList(),
        fulfillment: asMap(json['fulfillment']) == null ? null : Fulfillment.fromJson(asMap(json['fulfillment'])!),
        pausedCycle: asBoolOrNull(json['pausedCycle']),
      );

  Json toJson() => compact(<String, dynamic>{
        'id': id,
        'cycle': cycle,
        'status': status.wire,
        'issuedAt': issuedAt,
        'dueAt': dueAt,
        'paidAt': paidAt,
        'amount': amount.toJson(),
        'paymentMethod': paymentMethod?.wire,
        'paymentProfile': paymentProfile?.toJson(),
        'pix': pix?.toJson(),
        'items': items.map((e) => e.toJson()).toList(),
        'fulfillment': fulfillment?.toJson(),
        'pausedCycle': pausedCycle,
      });
}
