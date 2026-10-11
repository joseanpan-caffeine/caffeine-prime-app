import 'common.dart';
import 'json.dart';

/// Agregado diário. O app envia só agregados (nunca séries brutas) e exige o
/// consentimento `health_data`.
class HealthDailySample {
  const HealthDailySample({required this.date, required this.metric, required this.value, this.source});

  /// YYYY-MM-DD
  final String date;
  final HealthMetric metric;
  final double value;
  final String? source;

  factory HealthDailySample.fromJson(Json json) => HealthDailySample(
        date: asString(json['date']),
        metric: HealthMetric.parse(json['metric']),
        value: asDouble(json['value']),
        source: asStringOrNull(json['source']),
      );

  Json toJson() => compact(<String, dynamic>{
        'date': date,
        'metric': metric.wire,
        'value': value,
        'source': source,
      });
}

class HealthSyncRequest {
  const HealthSyncRequest({required this.samples});

  final List<HealthDailySample> samples;

  Json toJson() => <String, dynamic>{'samples': samples.map((e) => e.toJson()).toList()};
}

class HealthDay {
  const HealthDay({required this.date, this.steps, this.activeMinutes, this.workouts, this.sleepMinutes});

  final String date;
  final int? steps;
  final int? activeMinutes;
  final int? workouts;
  final int? sleepMinutes;

  factory HealthDay.fromJson(Json json) => HealthDay(
        date: asString(json['date']),
        steps: asIntOrNull(json['steps']),
        activeMinutes: asIntOrNull(json['activeMinutes']),
        workouts: asIntOrNull(json['workouts']),
        sleepMinutes: asIntOrNull(json['sleepMinutes']),
      );

  Json toJson() => compact(<String, dynamic>{
        'date': date,
        'steps': steps,
        'activeMinutes': activeMinutes,
        'workouts': workouts,
        'sleepMinutes': sleepMinutes,
      });
}

class HealthSuggestion {
  const HealthSuggestion({required this.id, required this.title, required this.body, this.productHandle, this.deepLink});

  final String id;
  final String title;
  final String body;
  final String? productHandle;
  final String? deepLink;

  factory HealthSuggestion.fromJson(Json json) => HealthSuggestion(
        id: asString(json['id']),
        title: asString(json['title']),
        body: asString(json['body']),
        productHandle: asStringOrNull(json['productHandle']),
        deepLink: asStringOrNull(json['deepLink']),
      );

  Json toJson() => compact(<String, dynamic>{
        'id': id,
        'title': title,
        'body': body,
        'productHandle': productHandle,
        'deepLink': deepLink,
      });
}

class HealthSummary {
  const HealthSummary({
    required this.connected,
    this.provider,
    this.lastSyncAt,
    required this.last7Days,
    required this.suggestions,
  });

  final bool connected;
  final HealthProvider? provider;
  final String? lastSyncAt;
  final List<HealthDay> last7Days;
  final List<HealthSuggestion> suggestions;

  static const HealthSummary disconnected =
      HealthSummary(connected: false, last7Days: <HealthDay>[], suggestions: <HealthSuggestion>[]);

  factory HealthSummary.fromJson(Json json) => HealthSummary(
        connected: asBool(json['connected']),
        provider: HealthProvider.parseOrNull(json['provider']),
        lastSyncAt: asStringOrNull(json['lastSyncAt']),
        last7Days: asMapList(json['last7Days']).map(HealthDay.fromJson).toList(),
        suggestions: asMapList(json['suggestions']).map(HealthSuggestion.fromJson).toList(),
      );

  Json toJson() => compact(<String, dynamic>{
        'connected': connected,
        'provider': provider?.wire,
        'lastSyncAt': lastSyncAt,
        'last7Days': last7Days.map((e) => e.toJson()).toList(),
        'suggestions': suggestions.map((e) => e.toJson()).toList(),
      });
}
