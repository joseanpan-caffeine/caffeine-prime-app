/// Utilidades puras para a rotina (sem dependência do Flutter, testáveis).
class StreakHelper {
  StreakHelper._();

  /// Conta dias consecutivos com conclusão >= [threshold], andando de trás para
  /// frente a partir do último dia da lista (que deve vir ordenada por data
  /// crescente). Um dia "hoje" ainda incompleto não zera a sequência.
  static int currentStreak(List<DayCompletion> days, {double threshold = 1.0, bool todayPending = true}) {
    if (days.isEmpty) return 0;
    int streak = 0;
    int i = days.length - 1;
    if (todayPending && days[i].completion < threshold) {
      i--; // hoje ainda pode ser concluído: ignora
    }
    for (; i >= 0; i--) {
      if (days[i].completion >= threshold) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Maior sequência histórica na lista.
  static int longestStreak(List<DayCompletion> days, {double threshold = 1.0}) {
    int best = 0;
    int cur = 0;
    for (final DayCompletion d in days) {
      if (d.completion >= threshold) {
        cur++;
        if (cur > best) best = cur;
      } else {
        cur = 0;
      }
    }
    return best;
  }

  /// Converte "07:30" em (hora, minuto). Devolve null se inválido.
  static ({int hour, int minute})? parseHhMm(String? value) {
    if (value == null) return null;
    final List<String> parts = value.split(':');
    if (parts.length != 2) return null;
    final int? h = int.tryParse(parts[0]);
    final int? m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) return null;
    return (hour: h, minute: m);
  }

  /// Id estável de notificação por item da rotina (hash curto, positivo).
  static int notificationId(String routineItemId) {
    int hash = 0;
    for (final int c in routineItemId.codeUnits) {
      hash = (hash * 31 + c) & 0x7FFFFFFF;
    }
    // Reserva a faixa 1..2^30 para lembretes da rotina.
    return (hash % 1000000000) + 1;
  }
}

class DayCompletion {
  const DayCompletion(this.date, this.completion);

  /// YYYY-MM-DD
  final String date;

  /// 0–1
  final double completion;
}
