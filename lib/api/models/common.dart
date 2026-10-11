import 'json.dart';

/// Money { amount: number (reais, 2 casas), currency: 'BRL' }
class Money {
  const Money({required this.amount, this.currency = 'BRL'});

  final double amount;
  final String currency;

  static const Money zero = Money(amount: 0);

  factory Money.fromJson(Json? json) {
    if (json == null) return Money.zero;
    return Money(
      amount: asDouble(json['amount']),
      currency: asString(json['currency'], 'BRL'),
    );
  }

  Json toJson() => <String, dynamic>{'amount': amount, 'currency': currency};

  @override
  bool operator ==(Object other) => other is Money && other.amount == amount && other.currency == currency;

  @override
  int get hashCode => Object.hash(amount, currency);

  @override
  String toString() => 'Money($amount $currency)';
}

/// Status da assinatura. `unknown` cobre strings fora do enum (a Prime API usa
/// string livre; o BFF normaliza para `active` + `rawStatus`, mas o app também
/// se protege — contexto-prime.md §8 item 5).
enum SubscriptionStatus {
  active('active'),
  future('future'),
  paused('paused'),
  canceled('canceled'),
  fraudReview('fraud_review'),
  unknown('unknown');

  const SubscriptionStatus(this.wire);
  final String wire;

  static SubscriptionStatus parse(dynamic v) {
    final String s = asString(v);
    for (final SubscriptionStatus e in SubscriptionStatus.values) {
      if (e.wire == s) return e;
    }
    return SubscriptionStatus.unknown;
  }
}

/// Frequência = fidelidade (não cadência de entrega; a cobrança é sempre a cada 30 dias).
enum Frequency {
  mensal('Mensal'),
  trimestral('Trimestral'),
  semestral('Semestral'),
  anual('Anual'),
  unknown('');

  const Frequency(this.wire);
  final String wire;

  String get label => this == Frequency.unknown ? 'Plano' : wire;

  static Frequency parse(dynamic v) {
    final String s = asString(v).toLowerCase();
    for (final Frequency e in Frequency.values) {
      if (e.wire.toLowerCase() == s && e != Frequency.unknown) return e;
    }
    return Frequency.unknown;
  }

  static Frequency? parseOrNull(dynamic v) {
    if (v == null) return null;
    final Frequency f = parse(v);
    return f == Frequency.unknown ? null : f;
  }
}

enum BillStatus {
  pending('pending'),
  paid('paid'),
  canceled('canceled'),
  review('review'),
  unknown('unknown');

  const BillStatus(this.wire);
  final String wire;

  static BillStatus parse(dynamic v) {
    final String s = asString(v);
    for (final BillStatus e in BillStatus.values) {
      if (e.wire == s) return e;
    }
    return BillStatus.unknown;
  }
}

/// ItemRecurrence: null = todo ciclo; 'on' | 'off' = alterna a cada 60 dias.
enum ItemRecurrence {
  everyCycle(null),
  on('on'),
  off('off');

  const ItemRecurrence(this.wire);
  final String? wire;

  bool get isSixtyDays => this != ItemRecurrence.everyCycle;

  static ItemRecurrence parse(dynamic v) {
    if (v == null) return ItemRecurrence.everyCycle;
    final String s = asString(v);
    if (s == 'on') return ItemRecurrence.on;
    if (s == 'off') return ItemRecurrence.off;
    return ItemRecurrence.everyCycle;
  }
}

enum PauseType {
  user('User'),
  offer('Offer');

  const PauseType(this.wire);
  final String wire;

  static PauseType parse(dynamic v) => asString(v) == 'Offer' ? PauseType.offer : PauseType.user;
}

enum FulfillmentStatus {
  pending('pending'),
  processing('processing'),
  shipped('shipped'),
  inTransit('in_transit'),
  outForDelivery('out_for_delivery'),
  delivered('delivered'),
  failed('failed'),
  unknown('unknown');

  const FulfillmentStatus(this.wire);
  final String wire;

  static FulfillmentStatus parse(dynamic v) {
    final String s = asString(v);
    for (final FulfillmentStatus e in FulfillmentStatus.values) {
      if (e.wire == s) return e;
    }
    return FulfillmentStatus.unknown;
  }

  String get label {
    switch (this) {
      case FulfillmentStatus.pending:
        return 'Aguardando';
      case FulfillmentStatus.processing:
        return 'Em preparo';
      case FulfillmentStatus.shipped:
        return 'Enviado';
      case FulfillmentStatus.inTransit:
        return 'Em trânsito';
      case FulfillmentStatus.outForDelivery:
        return 'Saiu para entrega';
      case FulfillmentStatus.delivered:
        return 'Entregue';
      case FulfillmentStatus.failed:
        return 'Falha na entrega';
      case FulfillmentStatus.unknown:
        return 'Status desconhecido';
    }
  }
}

enum PaymentMethod {
  creditCard('credit_card'),
  pix('pix'),
  unknown('unknown');

  const PaymentMethod(this.wire);
  final String wire;

  static PaymentMethod? parseOrNull(dynamic v) {
    if (v == null) return null;
    final String s = asString(v);
    if (s == 'credit_card') return PaymentMethod.creditCard;
    if (s == 'pix') return PaymentMethod.pix;
    return PaymentMethod.unknown;
  }
}

/// Razões de bloqueio calculadas no servidor (api.ts CapabilityReason).
enum CapabilityReason {
  editWindowClosed('EDIT_WINDOW_CLOSED'),
  subscriptionNotActive('SUBSCRIPTION_NOT_ACTIVE'),
  frequencyNotEligible('FREQUENCY_NOT_ELIGIBLE'),
  noPauseCredits('NO_PAUSE_CREDITS'),
  minPaidCycles('MIN_PAID_CYCLES'),
  pauseWindowClosed('PAUSE_WINDOW_CLOSED'),
  resumeWindowClosed('RESUME_WINDOW_CLOSED'),
  pendingBill('PENDING_BILL'),
  notPaused('NOT_PAUSED'),
  notCanceled('NOT_CANCELED'),
  cancellationBlocked('CANCELLATION_BLOCKED'),
  commitmentActive('COMMITMENT_ACTIVE'),
  cancelWindowClosed('CANCEL_WINDOW_CLOSED'),
  underReview('UNDER_REVIEW'),
  unknown('UNKNOWN');

  const CapabilityReason(this.wire);
  final String wire;

  static CapabilityReason? parseOrNull(dynamic v) {
    if (v == null) return null;
    final String s = asString(v);
    for (final CapabilityReason e in CapabilityReason.values) {
      if (e.wire == s) return e;
    }
    return CapabilityReason.unknown;
  }
}

enum ConsentKind {
  push('push'),
  healthData('health_data'),
  routineData('routine_data'),
  aiAssistant('ai_assistant'),
  analytics('analytics'),
  unknown('unknown');

  const ConsentKind(this.wire);
  final String wire;

  static ConsentKind parse(dynamic v) {
    final String s = asString(v);
    for (final ConsentKind e in ConsentKind.values) {
      if (e.wire == s) return e;
    }
    return ConsentKind.unknown;
  }

  String get label {
    switch (this) {
      case ConsentKind.push:
        return 'Notificações push';
      case ConsentKind.healthData:
        return 'Dados de saúde (relógio/app de exercício)';
      case ConsentKind.routineData:
        return 'Dados de rotina e hábitos';
      case ConsentKind.aiAssistant:
        return 'Assistente de IA (Prime IA)';
      case ConsentKind.analytics:
        return 'Análise de uso do app';
      case ConsentKind.unknown:
        return 'Outro';
    }
  }

  String get description {
    switch (this) {
      case ConsentKind.push:
        return 'Avisos de cobrança, envio, renovação e novidades no seu aparelho.';
      case ConsentKind.healthData:
        return 'Agregados diários (passos, minutos ativos, treinos, sono) do Apple Health ou Health Connect, '
            'usados só para sugerir sua rotina. Nunca enviamos séries brutas.';
      case ConsentKind.routineData:
        return 'Seus check-ins, lembretes e metas, para calcular sequência e previsão de estoque.';
      case ConsentKind.aiAssistant:
        return 'Suas perguntas ao assistente e o contexto da sua caixa e rotina para responder.';
      case ConsentKind.analytics:
        return 'Eventos de uso do app, ligados ao seu id de cliente, para melhorar o produto.';
      case ConsentKind.unknown:
        return '';
    }
  }
}

enum RoutineSlot {
  morning('morning'),
  preWorkout('pre_workout'),
  afternoon('afternoon'),
  evening('evening'),
  unknown('unknown');

  const RoutineSlot(this.wire);
  final String wire;

  static RoutineSlot parse(dynamic v) {
    final String s = asString(v);
    for (final RoutineSlot e in RoutineSlot.values) {
      if (e.wire == s) return e;
    }
    return RoutineSlot.unknown;
  }

  String get label {
    switch (this) {
      case RoutineSlot.morning:
        return 'Manhã';
      case RoutineSlot.preWorkout:
        return 'Pré-treino';
      case RoutineSlot.afternoon:
        return 'Tarde';
      case RoutineSlot.evening:
        return 'Noite';
      case RoutineSlot.unknown:
        return 'Horário';
    }
  }

  /// Horário sugerido quando o item não tem lembrete definido.
  String get defaultTime {
    switch (this) {
      case RoutineSlot.morning:
        return '07:30';
      case RoutineSlot.preWorkout:
        return '17:00';
      case RoutineSlot.afternoon:
        return '15:00';
      case RoutineSlot.evening:
        return '21:00';
      case RoutineSlot.unknown:
        return '09:00';
    }
  }
}

enum CheckInSource {
  manual('manual'),
  reminder('reminder'),
  wearable('wearable');

  const CheckInSource(this.wire);
  final String wire;

  static CheckInSource parse(dynamic v) {
    final String s = asString(v);
    for (final CheckInSource e in CheckInSource.values) {
      if (e.wire == s) return e;
    }
    return CheckInSource.manual;
  }
}

enum HealthMetric {
  steps('steps'),
  activeMinutes('active_minutes'),
  workouts('workouts'),
  sleepMinutes('sleep_minutes'),
  restingHeartRate('resting_heart_rate'),
  waterMl('water_ml'),
  unknown('unknown');

  const HealthMetric(this.wire);
  final String wire;

  static HealthMetric parse(dynamic v) {
    final String s = asString(v);
    for (final HealthMetric e in HealthMetric.values) {
      if (e.wire == s) return e;
    }
    return HealthMetric.unknown;
  }
}

enum HealthProvider {
  appleHealth('apple_health'),
  healthConnect('health_connect'),
  none('none');

  const HealthProvider(this.wire);
  final String wire;

  static HealthProvider? parseOrNull(dynamic v) {
    if (v == null) return null;
    final String s = asString(v);
    for (final HealthProvider e in HealthProvider.values) {
      if (e.wire == s) return e;
    }
    return HealthProvider.none;
  }
}

enum AssistantRole {
  user('user'),
  assistant('assistant');

  const AssistantRole(this.wire);
  final String wire;

  static AssistantRole parse(dynamic v) => asString(v) == 'user' ? AssistantRole.user : AssistantRole.assistant;
}
