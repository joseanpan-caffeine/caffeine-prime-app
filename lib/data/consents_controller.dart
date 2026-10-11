import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models/common.dart';
import '../api/models/device.dart';
import '../core/analytics.dart';
import 'providers.dart';

/// Concede/revoga consentimentos (LGPD) via PUT /me/consents, usando a versão
/// vigente de GET /config.
class ConsentsController {
  ConsentsController(this._ref);

  final Ref _ref;

  Future<void> setConsent(ConsentKind kind, bool granted) async {
    final String version = _ref.read(appConfigValueProvider).consentVersion(kind);
    await _ref.read(accountApiProvider).updateConsent(
          UpdateConsentRequest(kind: kind, granted: granted, version: version),
        );
    _ref.read(analyticsProvider).track(
      AnalyticsEvents.consentChange,
      params: <String, Object?>{'kind': kind.wire, 'granted': granted},
    );
    _ref.invalidate(consentsProvider);
  }
}

final Provider<ConsentsController> consentsControllerProvider =
    Provider<ConsentsController>((ref) => ConsentsController(ref));
