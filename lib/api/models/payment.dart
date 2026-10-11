import 'json.dart';

class VindiConfig {
  const VindiConfig({required this.publicKey, required this.apiUrl, required this.sandbox});

  final String publicKey;
  final String apiUrl;
  final bool sandbox;

  factory VindiConfig.fromJson(Json json) => VindiConfig(
        publicKey: asString(json['publicKey']),
        apiUrl: asString(json['apiUrl']),
        sandbox: asBool(json['sandbox']),
      );

  Json toJson() => <String, dynamic>{'publicKey': publicKey, 'apiUrl': apiUrl, 'sandbox': sandbox};
}

class AddCardRequest {
  const AddCardRequest({required this.gatewayToken, this.paymentCompanyCode, this.setAsDefault});

  final String gatewayToken;
  final String? paymentCompanyCode;
  final bool? setAsDefault;

  Json toJson() => compact(<String, dynamic>{
        'gatewayToken': gatewayToken,
        'paymentCompanyCode': paymentCompanyCode,
        'setAsDefault': setAsDefault,
      });
}

class PayWithNewCardRequest {
  const PayWithNewCardRequest({required this.gatewayToken, this.paymentCompanyCode});

  final String gatewayToken;
  final String? paymentCompanyCode;

  Json toJson() => compact(<String, dynamic>{
        'gatewayToken': gatewayToken,
        'paymentCompanyCode': paymentCompanyCode,
      });
}

/// Dados do cartão digitados no app. Só trafegam para a API pública da Vindi
/// (tokenização); o BFF recebe apenas o `gatewayToken`.
class NewCardInput {
  const NewCardInput({
    required this.holderName,
    required this.number,
    required this.expirationMonth,
    required this.expirationYear,
    required this.cvv,
    this.paymentCompanyCode,
  });

  final String holderName;
  final String number;

  /// MM
  final String expirationMonth;

  /// YY ou YYYY
  final String expirationYear;
  final String cvv;
  final String? paymentCompanyCode;

  String get digits => number.replaceAll(RegExp(r'\D'), '');
  String get lastFour => digits.length >= 4 ? digits.substring(digits.length - 4) : digits;

  /// Vindi espera MM/YY.
  String get vindiExpiration {
    final String y = expirationYear.length == 4 ? expirationYear.substring(2) : expirationYear;
    return '${expirationMonth.padLeft(2, '0')}/$y';
  }
}
