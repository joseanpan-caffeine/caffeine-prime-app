import 'common.dart';
import 'json.dart';

class Plan {
  const Plan({
    required this.frequency,
    required this.name,
    required this.commitmentMonths,
    required this.discountPercentage,
    required this.pauseCredits,
    this.highlight,
  });

  final Frequency frequency;
  final String name;
  final int commitmentMonths;
  final double discountPercentage;
  final int pauseCredits;
  final String? highlight;

  factory Plan.fromJson(Json json) => Plan(
        frequency: Frequency.parse(json['frequency']),
        name: asString(json['name']),
        commitmentMonths: asInt(json['commitmentMonths']),
        discountPercentage: asDouble(json['discountPercentage']),
        pauseCredits: asInt(json['pauseCredits']),
        highlight: asStringOrNull(json['highlight']),
      );

  Json toJson() => compact(<String, dynamic>{
        'frequency': frequency.wire,
        'name': name,
        'commitmentMonths': commitmentMonths,
        'discountPercentage': discountPercentage,
        'pauseCredits': pauseCredits,
        'highlight': highlight,
      });
}

class CatalogFlavor {
  const CatalogFlavor({required this.handle, required this.title, required this.inStock});

  final String handle;
  final String title;
  final bool inStock;

  factory CatalogFlavor.fromJson(Json json) => CatalogFlavor(
        handle: asString(json['handle']),
        title: asString(json['title']),
        inStock: asBool(json['inStock'], true),
      );

  Json toJson() => <String, dynamic>{'handle': handle, 'title': title, 'inStock': inStock};
}

class CatalogProduct {
  const CatalogProduct({
    required this.handle,
    required this.title,
    required this.category,
    this.imageUrl,
    required this.price,
    this.flavors,
    required this.inStock,
    required this.minQuantity,
    required this.maxQuantity,
  });

  final String handle;
  final String title;
  final String category;
  final String? imageUrl;
  final Money price;
  final List<CatalogFlavor>? flavors;
  final bool inStock;
  final int minQuantity;
  final int maxQuantity;

  factory CatalogProduct.fromJson(Json json) => CatalogProduct(
        handle: asString(json['handle']),
        title: asString(json['title']),
        category: asString(json['category'], 'Outros'),
        imageUrl: asStringOrNull(json['imageUrl']),
        price: Money.fromJson(asMap(json['price'])),
        flavors: json['flavors'] == null ? null : asMapList(json['flavors']).map(CatalogFlavor.fromJson).toList(),
        inStock: asBool(json['inStock'], true),
        minQuantity: asInt(json['minQuantity'], 0),
        maxQuantity: asInt(json['maxQuantity'], 99),
      );

  Json toJson() => compact(<String, dynamic>{
        'handle': handle,
        'title': title,
        'category': category,
        'imageUrl': imageUrl,
        'price': price.toJson(),
        'flavors': flavors?.map((e) => e.toJson()).toList(),
        'inStock': inStock,
        'minQuantity': minQuantity,
        'maxQuantity': maxQuantity,
      });
}

class DiscountTier {
  const DiscountTier({required this.minItems, required this.discountPercentage, required this.label});

  final int minItems;
  final double discountPercentage;
  final String label;

  factory DiscountTier.fromJson(Json json) => DiscountTier(
        minItems: asInt(json['minItems']),
        discountPercentage: asDouble(json['discountPercentage']),
        label: asString(json['label']),
      );

  Json toJson() => <String, dynamic>{
        'minItems': minItems,
        'discountPercentage': discountPercentage,
        'label': label,
      };
}

class CatalogGift {
  const CatalogGift({required this.handle, required this.title, this.imageUrl, this.requiresPlan});

  final String handle;
  final String title;
  final String? imageUrl;
  final List<Frequency>? requiresPlan;

  factory CatalogGift.fromJson(Json json) => CatalogGift(
        handle: asString(json['handle']),
        title: asString(json['title']),
        imageUrl: asStringOrNull(json['imageUrl']),
        requiresPlan: json['requiresPlan'] == null
            ? null
            : asStringList(json['requiresPlan']).map(Frequency.parse).where((f) => f != Frequency.unknown).toList(),
      );

  Json toJson() => compact(<String, dynamic>{
        'handle': handle,
        'title': title,
        'imageUrl': imageUrl,
        'requiresPlan': requiresPlan?.map((e) => e.wire).toList(),
      });

  bool availableFor(Frequency frequency) {
    if (requiresPlan == null || requiresPlan!.isEmpty) return true;
    return requiresPlan!.contains(frequency);
  }
}

class Catalog {
  const Catalog({required this.plans, required this.products, required this.discountTiers, required this.gifts});

  final List<Plan> plans;
  final List<CatalogProduct> products;
  final List<DiscountTier> discountTiers;
  final List<CatalogGift> gifts;

  factory Catalog.fromJson(Json json) => Catalog(
        plans: asMapList(json['plans']).map(Plan.fromJson).toList(),
        products: asMapList(json['products']).map(CatalogProduct.fromJson).toList(),
        discountTiers: asMapList(json['discountTiers']).map(DiscountTier.fromJson).toList(),
        gifts: asMapList(json['gifts']).map(CatalogGift.fromJson).toList(),
      );

  Json toJson() => <String, dynamic>{
        'plans': plans.map((e) => e.toJson()).toList(),
        'products': products.map((e) => e.toJson()).toList(),
        'discountTiers': discountTiers.map((e) => e.toJson()).toList(),
        'gifts': gifts.map((e) => e.toJson()).toList(),
      };

  /// Categorias na ordem em que aparecem.
  List<String> get categories {
    final List<String> out = <String>[];
    for (final CatalogProduct p in products) {
      if (!out.contains(p.category)) out.add(p.category);
    }
    return out;
  }
}
