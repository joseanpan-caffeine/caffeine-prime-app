import 'common.dart';
import 'json.dart';

class RegisterDeviceRequest {
  const RegisterDeviceRequest({
    required this.pushToken,
    this.pushProvider,
    required this.platform,
    required this.appVersion,
    this.deviceName,
  });

  final String pushToken;

  /// 'expo' | 'fcm' | 'apns'
  final String? pushProvider;

  /// 'ios' | 'android'
  final String platform;
  final String appVersion;
  final String? deviceName;

  Json toJson() => compact(<String, dynamic>{
        'pushToken': pushToken,
        'pushProvider': pushProvider,
        'platform': platform,
        'appVersion': appVersion,
        'deviceName': deviceName,
      });
}

class RegisteredDevice {
  const RegisteredDevice({required this.id});

  final String id;

  factory RegisteredDevice.fromJson(Json? json) => RegisteredDevice(id: asString(json?['id']));
}

class NotificationPreferences {
  const NotificationPreferences({
    required this.billing,
    required this.shipping,
    required this.renewal,
    required this.marketing,
    this.routine,
  });

  final bool billing;
  final bool shipping;
  final bool renewal;
  final bool marketing;

  /// Lembretes da rotina (frente 2).
  final bool? routine;

  static const NotificationPreferences defaults =
      NotificationPreferences(billing: true, shipping: true, renewal: true, marketing: false, routine: false);

  factory NotificationPreferences.fromJson(Json json) => NotificationPreferences(
        billing: asBool(json['billing'], true),
        shipping: asBool(json['shipping'], true),
        renewal: asBool(json['renewal'], true),
        marketing: asBool(json['marketing']),
        routine: asBoolOrNull(json['routine']),
      );

  Json toJson() => compact(<String, dynamic>{
        'billing': billing,
        'shipping': shipping,
        'renewal': renewal,
        'marketing': marketing,
        'routine': routine,
      });

  NotificationPreferences copyWith({bool? billing, bool? shipping, bool? renewal, bool? marketing, bool? routine}) {
    return NotificationPreferences(
      billing: billing ?? this.billing,
      shipping: shipping ?? this.shipping,
      renewal: renewal ?? this.renewal,
      marketing: marketing ?? this.marketing,
      routine: routine ?? this.routine,
    );
  }
}

// ---------- Consentimentos (LGPD) ----------

class Consent {
  const Consent({required this.kind, required this.granted, this.grantedAt, required this.version});

  final ConsentKind kind;
  final bool granted;
  final String? grantedAt;
  final String version;

  factory Consent.fromJson(Json json) => Consent(
        kind: ConsentKind.parse(json['kind']),
        granted: asBool(json['granted']),
        grantedAt: asStringOrNull(json['grantedAt']),
        version: asString(json['version'], '1'),
      );

  Json toJson() => compact(<String, dynamic>{
        'kind': kind.wire,
        'granted': granted,
        'grantedAt': grantedAt,
        'version': version,
      });
}

class UpdateConsentRequest {
  const UpdateConsentRequest({required this.kind, required this.granted, required this.version});

  final ConsentKind kind;
  final bool granted;
  final String version;

  Json toJson() => <String, dynamic>{'kind': kind.wire, 'granted': granted, 'version': version};
}
