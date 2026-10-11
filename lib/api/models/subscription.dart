import 'common.dart';
import 'json.dart';

class ProductItem {
  const ProductItem({
    required this.id,
    required this.handle,
    required this.title,
    this.flavor,
    this.imageUrl,
    this.sku,
    required this.quantity,
    required this.price,
    required this.discountPercentage,
    required this.finalPrice,
    required this.recurrence,
    this.cyclesLeft,
    this.isGift,
  });

  final String id;
  final String handle;
  final String title;
  final String? flavor;
  final String? imageUrl;
  final String? sku;
  final int quantity;

  /// preço cheio unitário
  final Money price;

  /// 0–100
  final double discountPercentage;

  /// unitário com desconto
  final Money finalPrice;
  final ItemRecurrence recurrence;

  /// item temporário
  final int? cyclesLeft;
  final bool? isGift;

  bool get gift => isGift ?? false;

  factory ProductItem.fromJson(Json json) => ProductItem(
        id: asString(json['id']),
        handle: asString(json['handle']),
        title: asString(json['title']),
        flavor: asStringOrNull(json['flavor']),
        imageUrl: asStringOrNull(json['imageUrl']),
        sku: asStringOrNull(json['sku']),
        quantity: asInt(json['quantity']),
        price: Money.fromJson(asMap(json['price'])),
        discountPercentage: asDouble(json['discountPercentage']),
        finalPrice: Money.fromJson(asMap(json['finalPrice'])),
        recurrence: ItemRecurrence.parse(json['recurrence']),
        cyclesLeft: asIntOrNull(json['cyclesLeft']),
        isGift: asBoolOrNull(json['isGift']),
      );

  Json toJson() => compact(<String, dynamic>{
        'id': id,
        'handle': handle,
        'title': title,
        'flavor': flavor,
        'imageUrl': imageUrl,
        'sku': sku,
        'quantity': quantity,
        'price': price.toJson(),
        'discountPercentage': discountPercentage,
        'finalPrice': finalPrice.toJson(),
        'recurrence': recurrence.wire,
        'cyclesLeft': cyclesLeft,
        'isGift': isGift,
      })
        // `recurrence: null` é significativo (todo ciclo): recoloca após o compact.
        ..['recurrence'] = recurrence.wire;
}

class Discount {
  const Discount({
    this.code,
    required this.percentage,
    this.temporaryCode,
    this.temporaryPercentage,
    this.temporaryCycles,
  });

  final String? code;
  final double percentage;
  final String? temporaryCode;
  final double? temporaryPercentage;
  final int? temporaryCycles;

  factory Discount.fromJson(Json? json) {
    if (json == null) return const Discount(percentage: 0);
    return Discount(
      code: asStringOrNull(json['code']),
      percentage: asDouble(json['percentage']),
      temporaryCode: asStringOrNull(json['temporaryCode']),
      temporaryPercentage: asDoubleOrNull(json['temporaryPercentage']),
      temporaryCycles: asIntOrNull(json['temporaryCycles']),
    );
  }

  Json toJson() => compact(<String, dynamic>{
        'code': code,
        'percentage': percentage,
        'temporaryCode': temporaryCode,
        'temporaryPercentage': temporaryPercentage,
        'temporaryCycles': temporaryCycles,
      });
}

class PaymentProfile {
  const PaymentProfile({
    required this.id,
    required this.brand,
    required this.lastFour,
    required this.holderName,
    required this.expiration,
    required this.isDefault,
  });

  final String id;

  /// Visa, Mastercard, Elo…
  final String brand;
  final String lastFour;
  final String holderName;

  /// MM/YYYY
  final String expiration;
  final bool isDefault;

  factory PaymentProfile.fromJson(Json json) => PaymentProfile(
        id: asString(json['id']),
        brand: asString(json['brand']),
        lastFour: asString(json['lastFour']),
        holderName: asString(json['holderName']),
        expiration: asString(json['expiration']),
        isDefault: asBool(json['isDefault']),
      );

  Json toJson() => <String, dynamic>{
        'id': id,
        'brand': brand,
        'lastFour': lastFour,
        'holderName': holderName,
        'expiration': expiration,
        'isDefault': isDefault,
      };
}

class ShippingAddress {
  const ShippingAddress({
    required this.id,
    required this.recipient,
    required this.postalCode,
    required this.street,
    required this.number,
    this.complement,
    required this.neighborhood,
    required this.city,
    required this.state,
    this.deliveryMethod,
    this.deliveryEstimateDays,
  });

  final String id;
  final String recipient;
  final String postalCode;
  final String street;
  final String number;
  final String? complement;
  final String neighborhood;
  final String city;
  final String state;
  final String? deliveryMethod;
  final int? deliveryEstimateDays;

  String get line1 => '$street, $number${complement != null && complement!.isNotEmpty ? ' - $complement' : ''}';
  String get line2 => '$neighborhood · $city/$state · CEP $postalCode';

  factory ShippingAddress.fromJson(Json json) => ShippingAddress(
        id: asString(json['id']),
        recipient: asString(json['recipient']),
        postalCode: asString(json['postalCode']),
        street: asString(json['street']),
        number: asString(json['number']),
        complement: asStringOrNull(json['complement']),
        neighborhood: asString(json['neighborhood']),
        city: asString(json['city']),
        state: asString(json['state']),
        deliveryMethod: asStringOrNull(json['deliveryMethod']),
        deliveryEstimateDays: asIntOrNull(json['deliveryEstimateDays']),
      );

  Json toJson() => compact(<String, dynamic>{
        'id': id,
        'recipient': recipient,
        'postalCode': postalCode,
        'street': street,
        'number': number,
        'complement': complement,
        'neighborhood': neighborhood,
        'city': city,
        'state': state,
        'deliveryMethod': deliveryMethod,
        'deliveryEstimateDays': deliveryEstimateDays,
      });
}

class SubscriptionPause {
  const SubscriptionPause({
    required this.cycles,
    required this.remainingCycles,
    required this.pausedAt,
    required this.resumeAt,
    this.pauseType,
  });

  final int cycles;
  final int remainingCycles;
  final String pausedAt;

  /// ISO
  final String resumeAt;

  /// ausente = User
  final PauseType? pauseType;

  factory SubscriptionPause.fromJson(Json json) => SubscriptionPause(
        cycles: asInt(json['cycles']),
        remainingCycles: asInt(json['remainingCycles']),
        pausedAt: asString(json['pausedAt']),
        resumeAt: asString(json['resumeAt']),
        pauseType: json['pauseType'] == null ? null : PauseType.parse(json['pauseType']),
      );

  Json toJson() => compact(<String, dynamic>{
        'cycles': cycles,
        'remainingCycles': remainingCycles,
        'pausedAt': pausedAt,
        'resumeAt': resumeAt,
        'pauseType': pauseType?.wire,
      });
}

class ScheduledChange {
  const ScheduledChange({
    required this.id,
    required this.appliesAt,
    required this.frequency,
    required this.planName,
    required this.items,
    required this.total,
    required this.nextCycleOnly,
  });

  final String id;

  /// ISO (= nextBillingAt)
  final String appliesAt;
  final Frequency frequency;
  final String planName;
  final List<ProductItem> items;
  final Money total;
  final bool nextCycleOnly;

  factory ScheduledChange.fromJson(Json json) => ScheduledChange(
        id: asString(json['id']),
        appliesAt: asString(json['appliesAt']),
        frequency: Frequency.parse(json['frequency']),
        planName: asString(json['planName']),
        items: asMapList(json['items']).map(ProductItem.fromJson).toList(),
        total: Money.fromJson(asMap(json['total'])),
        nextCycleOnly: asBool(json['nextCycleOnly']),
      );

  Json toJson() => <String, dynamic>{
        'id': id,
        'appliesAt': appliesAt,
        'frequency': frequency.wire,
        'planName': planName,
        'items': items.map((e) => e.toJson()).toList(),
        'total': total.toJson(),
        'nextCycleOnly': nextCycleOnly,
      };
}

/// Assinatura corrente do cliente.
///
/// `id` NUNCA deve ser guardado como permanente: na troca de plano a Prime API
/// cria uma assinatura nova e o id muda (contexto-prime.md §4.3, caso B).
class Subscription {
  const Subscription({
    required this.id,
    required this.status,
    this.rawStatus,
    required this.frequency,
    required this.planName,
    required this.startedAt,
    required this.nextBillingAt,
    required this.currentCycle,
    required this.paidCycles,
    required this.remainingCommitmentMonths,
    required this.pauseCreditsLeft,
    required this.items,
    required this.discount,
    this.paymentProfile,
    this.shippingAddress,
    this.pause,
    this.scheduledChange,
    required this.subtotal,
    required this.totalDiscount,
    required this.total,
  });

  final String id;
  final SubscriptionStatus status;

  /// Presente quando a Prime API devolveu um status fora do enum.
  final String? rawStatus;
  final Frequency frequency;
  final String planName;
  final String startedAt;
  final String nextBillingAt;
  final int currentCycle;
  final int paidCycles;

  /// -1 para Mensal
  final int remainingCommitmentMonths;
  final int pauseCreditsLeft;
  final List<ProductItem> items;
  final Discount discount;
  final PaymentProfile? paymentProfile;
  final ShippingAddress? shippingAddress;
  final SubscriptionPause? pause;
  final ScheduledChange? scheduledChange;
  final Money subtotal;
  final Money totalDiscount;
  final Money total;

  /// True quando o status veio desconhecido (mostrar "Status: {rawStatus}").
  bool get hasUnknownStatus => (rawStatus != null && rawStatus!.isNotEmpty) || status == SubscriptionStatus.unknown;

  factory Subscription.fromJson(Json json) => Subscription(
        id: asString(json['id']),
        status: SubscriptionStatus.parse(json['status']),
        rawStatus: asStringOrNull(json['rawStatus']),
        frequency: Frequency.parse(json['frequency']),
        planName: asString(json['planName']),
        startedAt: asString(json['startedAt']),
        nextBillingAt: asString(json['nextBillingAt']),
        currentCycle: asInt(json['currentCycle']),
        paidCycles: asInt(json['paidCycles']),
        remainingCommitmentMonths: asInt(json['remainingCommitmentMonths'], -1),
        pauseCreditsLeft: asInt(json['pauseCreditsLeft']),
        items: asMapList(json['items']).map(ProductItem.fromJson).toList(),
        discount: Discount.fromJson(asMap(json['discount'])),
        paymentProfile: asMap(json['paymentProfile']) == null ? null : PaymentProfile.fromJson(asMap(json['paymentProfile'])!),
        shippingAddress:
            asMap(json['shippingAddress']) == null ? null : ShippingAddress.fromJson(asMap(json['shippingAddress'])!),
        pause: asMap(json['pause']) == null ? null : SubscriptionPause.fromJson(asMap(json['pause'])!),
        scheduledChange:
            asMap(json['scheduledChange']) == null ? null : ScheduledChange.fromJson(asMap(json['scheduledChange'])!),
        subtotal: Money.fromJson(asMap(json['subtotal'])),
        totalDiscount: Money.fromJson(asMap(json['totalDiscount'])),
        total: Money.fromJson(asMap(json['total'])),
      );

  Json toJson() => compact(<String, dynamic>{
        'id': id,
        'status': status.wire,
        'rawStatus': rawStatus,
        'frequency': frequency.wire,
        'planName': planName,
        'startedAt': startedAt,
        'nextBillingAt': nextBillingAt,
        'currentCycle': currentCycle,
        'paidCycles': paidCycles,
        'remainingCommitmentMonths': remainingCommitmentMonths,
        'pauseCreditsLeft': pauseCreditsLeft,
        'items': items.map((e) => e.toJson()).toList(),
        'discount': discount.toJson(),
        'paymentProfile': paymentProfile?.toJson(),
        'shippingAddress': shippingAddress?.toJson(),
        'pause': pause?.toJson(),
        'scheduledChange': scheduledChange?.toJson(),
        'subtotal': subtotal.toJson(),
        'totalDiscount': totalDiscount.toJson(),
        'total': total.toJson(),
      });
}
