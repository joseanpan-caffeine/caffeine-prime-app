import 'bills.dart';
import 'capabilities.dart';
import 'common.dart';
import 'json.dart';
import 'profile.dart';
import 'subscription.dart';

class LastCanceled {
  const LastCanceled({required this.canceledAt, this.reason, required this.subscriptionId});

  final String canceledAt;
  final String? reason;
  final String subscriptionId;

  factory LastCanceled.fromJson(Json json) => LastCanceled(
        canceledAt: asString(json['canceledAt']),
        reason: asStringOrNull(json['reason']),
        subscriptionId: asString(json['subscriptionId']),
      );

  Json toJson() => compact(<String, dynamic>{
        'canceledAt': canceledAt,
        'reason': reason,
        'subscriptionId': subscriptionId,
      });
}

class Savings {
  const Savings({required this.last12Months, required this.sinceStart});

  final Money last12Months;
  final Money sinceStart;

  static const Savings zero = Savings(last12Months: Money.zero, sinceStart: Money.zero);

  factory Savings.fromJson(Json? json) {
    if (json == null) return Savings.zero;
    return Savings(
      last12Months: Money.fromJson(asMap(json['last12Months'])),
      sinceStart: Money.fromJson(asMap(json['sinceStart'])),
    );
  }

  Json toJson() => <String, dynamic>{
        'last12Months': last12Months.toJson(),
        'sinceStart': sinceStart.toJson(),
      };
}

class Wallet {
  const Wallet({required this.points, required this.label});

  final int points;
  final String label;

  static const Wallet empty = Wallet(points: 0, label: 'pontos');

  factory Wallet.fromJson(Json? json) {
    if (json == null) return Wallet.empty;
    return Wallet(points: asInt(json['points']), label: asString(json['label'], 'pontos'));
  }

  Json toJson() => <String, dynamic>{'points': points, 'label': label};
}

class PromoBanner {
  const PromoBanner({required this.id, required this.title, this.subtitle, this.imageUrl, this.deepLink});

  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? deepLink;

  factory PromoBanner.fromJson(Json json) => PromoBanner(
        id: asString(json['id']),
        title: asString(json['title']),
        subtitle: asStringOrNull(json['subtitle']),
        imageUrl: asStringOrNull(json['imageUrl']),
        deepLink: asStringOrNull(json['deepLink']),
      );

  Json toJson() => compact(<String, dynamic>{
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'imageUrl': imageUrl,
        'deepLink': deepLink,
      });
}

class Dashboard {
  const Dashboard({
    required this.user,
    this.subscription,
    this.lastCanceled,
    required this.capabilities,
    this.latestBill,
    this.tracking,
    required this.savings,
    required this.wallet,
    required this.banners,
  });

  final UserProfile user;
  final Subscription? subscription;
  final LastCanceled? lastCanceled;
  final Capabilities capabilities;
  final Bill? latestBill;
  final Fulfillment? tracking;
  final Savings savings;
  final Wallet wallet;
  final List<PromoBanner> banners;

  factory Dashboard.fromJson(Json json) => Dashboard(
        user: UserProfile.fromJson(asMap(json['user']) ?? const <String, dynamic>{}),
        subscription: asMap(json['subscription']) == null ? null : Subscription.fromJson(asMap(json['subscription'])!),
        lastCanceled: asMap(json['lastCanceled']) == null ? null : LastCanceled.fromJson(asMap(json['lastCanceled'])!),
        capabilities: Capabilities.fromJson(asMap(json['capabilities'])),
        latestBill: asMap(json['latestBill']) == null ? null : Bill.fromJson(asMap(json['latestBill'])!),
        tracking: asMap(json['tracking']) == null ? null : Fulfillment.fromJson(asMap(json['tracking'])!),
        savings: Savings.fromJson(asMap(json['savings'])),
        wallet: Wallet.fromJson(asMap(json['wallet'])),
        banners: asMapList(json['banners']).map(PromoBanner.fromJson).toList(),
      );

  Json toJson() => compact(<String, dynamic>{
        'user': user.toJson(),
        'subscription': subscription?.toJson(),
        'lastCanceled': lastCanceled?.toJson(),
        'capabilities': capabilities.toJson(),
        'latestBill': latestBill?.toJson(),
        'tracking': tracking?.toJson(),
        'savings': savings.toJson(),
        'wallet': wallet.toJson(),
        'banners': banners.map((e) => e.toJson()).toList(),
      });
}
