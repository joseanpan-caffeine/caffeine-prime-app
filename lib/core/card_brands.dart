/// Logos de bandeiras de cartão e do PIX embutidos em `assets/brand/`.
class CardBrands {
  CardBrands._();

  static const String visa = 'assets/brand/logo-visa.svg';
  static const String mastercard = 'assets/brand/logo-mastercard.svg';
  static const String elo = 'assets/brand/logo-elo.svg';
  static const String amex = 'assets/brand/logo-american_express.svg';
  static const String hipercard = 'assets/brand/logo-hipercard.svg';
  static const String pix = 'assets/brand/pix.svg';

  /// Devolve o asset da bandeira ou `null` quando desconhecida (a UI mostra
  /// um ícone genérico nesse caso).
  static String? forBrand(String? brand) {
    if (brand == null) return null;
    final String b = brand.toLowerCase().replaceAll(' ', '').replaceAll('_', '');
    if (b.contains('visa')) return visa;
    if (b.contains('master')) return mastercard;
    if (b.contains('elo')) return elo;
    if (b.contains('amex') || b.contains('american')) return amex;
    if (b.contains('hiper')) return hipercard;
    return null;
  }

  /// Código `payment_company_code` da Vindi a partir do nome da bandeira.
  static String? vindiCompanyCode(String? brand) {
    if (brand == null) return null;
    final String b = brand.toLowerCase();
    if (b.contains('visa')) return 'visa';
    if (b.contains('master')) return 'mastercard';
    if (b.contains('elo')) return 'elo';
    if (b.contains('amex') || b.contains('american')) return 'american_express';
    if (b.contains('hiper')) return 'hipercard';
    if (b.contains('diners')) return 'diners_club';
    return null;
  }

  /// Detecta a bandeira pelo número do cartão (apenas para escolher o logo e o
  /// `payment_company_code`; a validação real é da Vindi).
  static String? detectFromNumber(String number) {
    final String n = number.replaceAll(RegExp(r'\D'), '');
    if (n.isEmpty) return null;
    if (RegExp(r'^(4011|4312|4389|4514|4576|5041|5066|5067|509|6277|6362|6363|650|6516|6550)').hasMatch(n)) {
      return 'Elo';
    }
    if (RegExp(r'^(606282|3841)').hasMatch(n)) return 'Hipercard';
    if (n.startsWith('4')) return 'Visa';
    if (RegExp(r'^(5[1-5]|2[2-7])').hasMatch(n)) return 'Mastercard';
    if (RegExp(r'^3[47]').hasMatch(n)) return 'American Express';
    if (RegExp(r'^3(0[0-5]|[68])').hasMatch(n)) return 'Diners';
    return null;
  }
}
