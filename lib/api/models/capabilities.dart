import 'common.dart';
import 'json.dart';

/// Capacidade calculada no servidor. O app nunca calcula prazos: usa `until`
/// (quando bloqueada) e `closesAt` (quando permitida com janela).
class Capability {
  const Capability({
    required this.allowed,
    this.reason,
    this.until,
    this.closesAt,
    this.creditsLeft,
    this.maxCycles,
    this.remainingCommitmentMonths,
    this.earlyWindow,
    this.commitmentEndsAt,
  });

  final bool allowed;
  final CapabilityReason? reason;

  /// ISO: quando a ação reabre.
  final String? until;

  /// ISO: quando a ação deixa de ser permitida.
  final String? closesAt;

  // Extras de canPause
  final int? creditsLeft;
  final int? maxCycles;

  // Extras de canCancel
  final int? remainingCommitmentMonths;
  final bool? earlyWindow;

  /// Estimativa (ciclo de 30 dias, não dia fixo do mês).
  final String? commitmentEndsAt;

  static const Capability denied = Capability(allowed: false);

  factory Capability.fromJson(Json? json) {
    if (json == null) return Capability.denied;
    return Capability(
      allowed: asBool(json['allowed']),
      reason: CapabilityReason.parseOrNull(json['reason']),
      until: asStringOrNull(json['until']),
      closesAt: asStringOrNull(json['closesAt']),
      creditsLeft: asIntOrNull(json['creditsLeft']),
      maxCycles: asIntOrNull(json['maxCycles']),
      remainingCommitmentMonths: asIntOrNull(json['remainingCommitmentMonths']),
      earlyWindow: asBoolOrNull(json['earlyWindow']),
      commitmentEndsAt: asStringOrNull(json['commitmentEndsAt']),
    );
  }

  Json toJson() => compact(<String, dynamic>{
        'allowed': allowed,
        'reason': reason?.wire,
        'until': until,
        'closesAt': closesAt,
        'creditsLeft': creditsLeft,
        'maxCycles': maxCycles,
        'remainingCommitmentMonths': remainingCommitmentMonths,
        'earlyWindow': earlyWindow,
        'commitmentEndsAt': commitmentEndsAt,
      });
}

class PendingBillSummary {
  const PendingBillSummary({required this.id, required this.amount, required this.dueAt, required this.pixAvailable});

  final String id;
  final Money amount;
  final String dueAt;
  final bool pixAvailable;

  factory PendingBillSummary.fromJson(Json json) => PendingBillSummary(
        id: asString(json['id']),
        amount: Money.fromJson(asMap(json['amount'])),
        dueAt: asString(json['dueAt']),
        pixAvailable: asBool(json['pixAvailable']),
      );

  Json toJson() => <String, dynamic>{
        'id': id,
        'amount': amount.toJson(),
        'dueAt': dueAt,
        'pixAvailable': pixAvailable,
      };
}

class Capabilities {
  const Capabilities({
    required this.canEdit,
    required this.canPause,
    required this.canResume,
    required this.canCancel,
    required this.canReactivate,
    required this.canChangeCard,
    required this.canChangeAddress,
    required this.hasPendingBill,
    this.pendingBill,
  });

  final Capability canEdit;
  final Capability canPause;
  final Capability canResume;
  final Capability canCancel;
  final Capability canReactivate;
  final Capability canChangeCard;
  final Capability canChangeAddress;
  final bool hasPendingBill;
  final PendingBillSummary? pendingBill;

  static const Capabilities none = Capabilities(
    canEdit: Capability.denied,
    canPause: Capability.denied,
    canResume: Capability.denied,
    canCancel: Capability.denied,
    canReactivate: Capability.denied,
    canChangeCard: Capability.denied,
    canChangeAddress: Capability.denied,
    hasPendingBill: false,
  );

  factory Capabilities.fromJson(Json? json) {
    if (json == null) return Capabilities.none;
    return Capabilities(
      canEdit: Capability.fromJson(asMap(json['canEdit'])),
      canPause: Capability.fromJson(asMap(json['canPause'])),
      canResume: Capability.fromJson(asMap(json['canResume'])),
      canCancel: Capability.fromJson(asMap(json['canCancel'])),
      canReactivate: Capability.fromJson(asMap(json['canReactivate'])),
      canChangeCard: Capability.fromJson(asMap(json['canChangeCard'])),
      canChangeAddress: Capability.fromJson(asMap(json['canChangeAddress'])),
      hasPendingBill: asBool(json['hasPendingBill']),
      pendingBill: asMap(json['pendingBill']) == null ? null : PendingBillSummary.fromJson(asMap(json['pendingBill'])!),
    );
  }

  Json toJson() => compact(<String, dynamic>{
        'canEdit': canEdit.toJson(),
        'canPause': canPause.toJson(),
        'canResume': canResume.toJson(),
        'canCancel': canCancel.toJson(),
        'canReactivate': canReactivate.toJson(),
        'canChangeCard': canChangeCard.toJson(),
        'canChangeAddress': canChangeAddress.toJson(),
        'hasPendingBill': hasPendingBill,
        'pendingBill': pendingBill?.toJson(),
      });
}

/// Textos pt-BR das razões de bloqueio (exibidos junto da ação desabilitada).
String capabilityReasonLabel(CapabilityReason? reason, {String? until}) {
  switch (reason) {
    case CapabilityReason.editWindowClosed:
      return 'Edição indisponível: a caixa já está sendo preparada para a próxima cobrança.';
    case CapabilityReason.subscriptionNotActive:
      return 'Disponível só com a assinatura ativa.';
    case CapabilityReason.frequencyNotEligible:
      return 'Seu plano não dá direito a pausa.';
    case CapabilityReason.noPauseCredits:
      return 'Você não tem créditos de pausa neste período.';
    case CapabilityReason.minPaidCycles:
      return 'A pausa fica disponível a partir da 4ª cobrança paga.';
    case CapabilityReason.pauseWindowClosed:
      return 'O pedido de pausa fecha 3 dias antes da cobrança.';
    case CapabilityReason.resumeWindowClosed:
      return 'Desfazer a pausa só é possível até 5 dias antes da cobrança do ciclo pausado.';
    case CapabilityReason.pendingBill:
      return 'Regularize o pagamento pendente para continuar.';
    case CapabilityReason.notPaused:
      return 'A assinatura não está pausada.';
    case CapabilityReason.notCanceled:
      return 'A assinatura não está cancelada.';
    case CapabilityReason.cancellationBlocked:
      return 'Cancelamento indisponível no momento. Fale com a gente.';
    case CapabilityReason.commitmentActive:
      return 'Sua fidelidade ainda está em vigor.';
    case CapabilityReason.cancelWindowClosed:
      return 'Hoje é dia de cobrança: o cancelamento reabre após a renovação.';
    case CapabilityReason.underReview:
      return 'Sua assinatura está em análise.';
    case CapabilityReason.unknown:
      return 'Ação indisponível no momento.';
    case null:
      return 'Ação indisponível no momento.';
  }
}
