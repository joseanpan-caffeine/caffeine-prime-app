import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Nomes de eventos rastreados nas ações-chave do app.
class AnalyticsEvents {
  AnalyticsEvents._();

  static const String login = 'login';
  static const String logout = 'logout';
  static const String screenView = 'screen_view';
  static const String boxEditPreview = 'box_edit_preview';
  static const String boxEditConfirm = 'box_edit_confirm';
  static const String scheduleCancel = 'schedule_cancel';
  static const String pauseRequest = 'pause_request';
  static const String resumeRequest = 'resume_request';
  static const String cancelRequest = 'cancel_request';
  static const String reactivateRequest = 'reactivate_request';
  static const String payPix = 'pay_pix';
  static const String payCurrentCard = 'pay_current_card';
  static const String payNewCard = 'pay_new_card';
  static const String cardAdd = 'card_add';
  static const String addressUpdate = 'address_update';
  static const String routineCheckIn = 'routine_check_in';
  static const String routineUndo = 'routine_undo';
  static const String routineReminderSet = 'routine_reminder_set';
  static const String healthConnect = 'health_connect';
  static const String healthSync = 'health_sync';
  static const String assistantSend = 'assistant_send';
  static const String consentChange = 'consent_change';
  static const String deleteAccountRequest = 'delete_account_request';
}

/// Interface de analytics. Todo evento carrega `customerId` (= shopifyCustomerId)
/// para cruzar com `assinaturas_prime.id_shopify` no BigQuery
/// (contexto-prime.md §9). Dado de saúde/hábito só é enviado com consentimento;
/// a implementação real deve respeitar o consentimento `analytics`.
abstract class Analytics {
  /// Define (ou limpa) o cliente logado.
  void setCustomer(String? customerId);

  /// Registra um evento. [params] não deve conter dado pessoal sensível.
  void track(String event, {Map<String, Object?> params = const <String, Object?>{}});

  void screen(String name) => track(AnalyticsEvents.screenView, params: <String, Object?>{'screen': name});
}

/// Implementação vazia: só loga em debug. Troque por Firebase Analytics /
/// Amplitude quando o time de Dados decidir o destino dos eventos.
class NoopAnalytics extends Analytics {
  String? _customerId;

  @override
  void setCustomer(String? customerId) {
    _customerId = customerId;
  }

  @override
  void track(String event, {Map<String, Object?> params = const <String, Object?>{}}) {
    if (kDebugMode) {
      debugPrint('[analytics] $event customerId=${_customerId ?? '-'} $params');
    }
  }
}

final Provider<Analytics> analyticsProvider = Provider<Analytics>((ref) => NoopAnalytics());
