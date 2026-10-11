import 'common.dart';
import 'json.dart';

class ConfigLinks {
  const ConfigLinks({
    required this.privacy,
    required this.terms,
    required this.support,
    required this.subscribeUrl,
    this.healthPrivacy,
  });

  final String privacy;
  final String terms;
  final String support;
  final String subscribeUrl;
  final String? healthPrivacy;

  static const ConfigLinks empty = ConfigLinks(
    privacy: 'https://www.caffeinearmy.com.br/policies/privacy-policy',
    terms: 'https://www.caffeinearmy.com.br/policies/terms-of-service',
    support: 'https://www.caffeinearmy.com.br/pages/contato',
    subscribeUrl: 'https://www.caffeinearmy.com.br/caffeine-prime',
  );

  factory ConfigLinks.fromJson(Json? json) {
    if (json == null) return ConfigLinks.empty;
    return ConfigLinks(
      privacy: asString(json['privacy'], ConfigLinks.empty.privacy),
      terms: asString(json['terms'], ConfigLinks.empty.terms),
      support: asString(json['support'], ConfigLinks.empty.support),
      subscribeUrl: asString(json['subscribeUrl'], ConfigLinks.empty.subscribeUrl),
      healthPrivacy: asStringOrNull(json['healthPrivacy']),
    );
  }

  Json toJson() => compact(<String, dynamic>{
        'privacy': privacy,
        'terms': terms,
        'support': support,
        'subscribeUrl': subscribeUrl,
        'healthPrivacy': healthPrivacy,
      });
}

class AppConfig {
  const AppConfig({
    required this.minSupportedVersion,
    required this.features,
    required this.links,
    required this.consentVersions,
  });

  final String minSupportedVersion;

  /// Flags: routine, health, assistant, clubeVantagens, caffeineX…
  final Map<String, bool> features;
  final ConfigLinks links;

  /// Versões vigentes dos termos de consentimento.
  final Map<ConsentKind, String> consentVersions;

  static const AppConfig defaults = AppConfig(
    minSupportedVersion: '0.0.0',
    features: <String, bool>{'routine': true, 'health': true, 'assistant': true, 'clubeVantagens': true, 'caffeineX': true},
    links: ConfigLinks.empty,
    consentVersions: <ConsentKind, String>{},
  );

  bool feature(String name, {bool fallback = true}) => features[name] ?? fallback;

  /// Versão vigente de um consentimento (fallback '1').
  String consentVersion(ConsentKind kind) => consentVersions[kind] ?? '1';

  factory AppConfig.fromJson(Json json) {
    final Map<String, bool> features = <String, bool>{};
    final Json? f = asMap(json['features']);
    if (f != null) {
      f.forEach((key, value) => features[key] = asBool(value));
    }
    final Map<ConsentKind, String> versions = <ConsentKind, String>{};
    final Json? cv = asMap(json['consentVersions']);
    if (cv != null) {
      cv.forEach((key, value) {
        final ConsentKind kind = ConsentKind.parse(key);
        if (kind != ConsentKind.unknown && value != null) versions[kind] = value.toString();
      });
    }
    return AppConfig(
      minSupportedVersion: asString(json['minSupportedVersion'], '0.0.0'),
      features: features,
      links: ConfigLinks.fromJson(asMap(json['links'])),
      consentVersions: versions,
    );
  }

  Json toJson() => <String, dynamic>{
        'minSupportedVersion': minSupportedVersion,
        'features': features,
        'links': links.toJson(),
        'consentVersions': consentVersions.map((k, v) => MapEntry(k.wire, v)),
      };
}
