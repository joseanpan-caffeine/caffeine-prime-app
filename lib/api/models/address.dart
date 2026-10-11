import 'common.dart';
import 'json.dart';

class AddressQuoteRequest {
  const AddressQuoteRequest({required this.postalCode});

  final String postalCode;

  Json toJson() => <String, dynamic>{'postalCode': postalCode};
}

class AddressQuoteOption {
  const AddressQuoteOption({
    required this.id,
    required this.method,
    required this.carrier,
    required this.estimateDays,
    required this.price,
  });

  final String id;
  final String method;
  final String carrier;
  final int estimateDays;

  /// Frete é sempre grátis para o assinante; o valor aqui é informativo
  /// (teto de aprovação do servidor).
  final Money price;

  factory AddressQuoteOption.fromJson(Json json) => AddressQuoteOption(
        id: asString(json['id']),
        method: asString(json['method']),
        carrier: asString(json['carrier']),
        estimateDays: asInt(json['estimateDays']),
        price: Money.fromJson(asMap(json['price'])),
      );

  Json toJson() => <String, dynamic>{
        'id': id,
        'method': method,
        'carrier': carrier,
        'estimateDays': estimateDays,
        'price': price.toJson(),
      };
}

class AddressQuote {
  const AddressQuote({
    required this.postalCode,
    required this.city,
    required this.state,
    this.street,
    this.neighborhood,
    required this.options,
  });

  final String postalCode;
  final String city;
  final String state;
  final String? street;
  final String? neighborhood;
  final List<AddressQuoteOption> options;

  factory AddressQuote.fromJson(Json json) => AddressQuote(
        postalCode: asString(json['postalCode']),
        city: asString(json['city']),
        state: asString(json['state']),
        street: asStringOrNull(json['street']),
        neighborhood: asStringOrNull(json['neighborhood']),
        options: asMapList(json['options']).map(AddressQuoteOption.fromJson).toList(),
      );

  Json toJson() => compact(<String, dynamic>{
        'postalCode': postalCode,
        'city': city,
        'state': state,
        'street': street,
        'neighborhood': neighborhood,
        'options': options.map((e) => e.toJson()).toList(),
      });
}

/// UpdateAddressRequest = ShippingAddress sem id/deliveryMethod/deliveryEstimateDays + quoteOptionId.
class UpdateAddressRequest {
  const UpdateAddressRequest({
    required this.recipient,
    required this.postalCode,
    required this.street,
    required this.number,
    this.complement,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.quoteOptionId,
  });

  final String recipient;
  final String postalCode;
  final String street;
  final String number;
  final String? complement;
  final String neighborhood;
  final String city;
  final String state;
  final String quoteOptionId;

  Json toJson() => compact(<String, dynamic>{
        'recipient': recipient,
        'postalCode': postalCode,
        'street': street,
        'number': number,
        'complement': complement,
        'neighborhood': neighborhood,
        'city': city,
        'state': state,
        'quoteOptionId': quoteOptionId,
      });
}
