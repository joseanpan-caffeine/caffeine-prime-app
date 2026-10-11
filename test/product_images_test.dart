import 'package:caffeine_prime/core/card_brands.dart';
import 'package:caffeine_prime/core/product_images.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductImages.forProduct', () {
    test('handles da Shopify', () {
      expect(ProductImages.forProduct(handle: 'supercoffee-chocolate-economic-size'), ProductImages.supercoffeeChocolate380);
      expect(ProductImages.forProduct(handle: 'supercoffee-original-classic-size'), ProductImages.supercoffeeOriginal220);
      expect(ProductImages.forProduct(handle: 'supercoffee-baunilha-economic-size'), ProductImages.supercoffeeVanilla380);
      expect(ProductImages.forProduct(handle: 'supercoffee-choconilla-economic-size'), ProductImages.supercoffeeChoconilla380);
      expect(ProductImages.forProduct(handle: 'supercoffee-to-go-pacoca'), ProductImages.supercoffeeToGoPacoca);
      expect(ProductImages.forProduct(handle: 'morning-shot-limao-stick'), ProductImages.morningShot);
      expect(ProductImages.forProduct(handle: 'whey-baunilha-420g'), ProductImages.whey);
      expect(ProductImages.forProduct(handle: 'creatina-250g'), ProductImages.whey);
    });
    test('título com acento e fallback', () {
      expect(ProductImages.forProduct(title: 'SuperCoffee Paçoca To Go'), ProductImages.supercoffeeToGoPacoca);
      expect(ProductImages.forProduct(title: 'Coisa desconhecida'), ProductImages.fallback);
      expect(ProductImages.forProduct(), ProductImages.fallback);
    });
  });

  group('CardBrands', () {
    test('logo por nome e por número', () {
      expect(CardBrands.forBrand('Mastercard'), CardBrands.mastercard);
      expect(CardBrands.forBrand('VISA'), CardBrands.visa);
      expect(CardBrands.forBrand('American Express'), CardBrands.amex);
      expect(CardBrands.forBrand('Desconhecida'), isNull);
      expect(CardBrands.detectFromNumber('4111 1111 1111 1111'), 'Visa');
      expect(CardBrands.detectFromNumber('5555555555554444'), 'Mastercard');
      expect(CardBrands.detectFromNumber('378282246310005'), 'American Express');
      expect(CardBrands.vindiCompanyCode('American Express'), 'american_express');
    });
  });
}
