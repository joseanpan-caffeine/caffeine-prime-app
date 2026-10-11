import 'package:intl/intl.dart';

import '../api/models/common.dart';

/// Formatação pt-BR de dinheiro e datas.
///
/// Importante (contexto-prime.md §12): o app NÃO recalcula valores nem prazos;
/// só formata o que a API devolve. Datas em ISO com offset de São Paulo são
/// exibidas no fuso em que vieram (sem converter para o fuso do aparelho) para
/// que "até 14/07" bata com a regra calculada no servidor.
class Fmt {
  Fmt._();

  static final NumberFormat _money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 2);
  static final NumberFormat _int = NumberFormat.decimalPattern('pt_BR');

  /// R$ 178,80
  static String money(Money? m) {
    if (m == null) return '—';
    return amount(m.amount);
  }

  /// R$ 178,80 a partir de um número.
  static String amount(num value) {
    // NumberFormat.currency com símbolo gera "R$ 178,80" (espaço não separável).
    return _money.format(value).replaceAll(' ', ' ');
  }

  /// 1.580
  static String integer(num value) => _int.format(value);

  /// 15% → "15%"; 12.5 → "12,5%"
  static String percent(num value) {
    if (value == value.roundToDouble()) return '${value.toInt()}%';
    return '${value.toString().replaceAll('.', ',')}%';
  }

  static const List<String> _monthsLong = <String>[
    'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
  ];
  static const List<String> _monthsShort = <String>[
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez',
  ];
  static const List<String> _weekdaysShort = <String>['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];

  /// Interpreta uma string ISO preservando a hora "de parede" do offset em que
  /// veio (ex.: `2026-07-14T00:00:00-03:00` → 14/07 00:00), em vez de converter
  /// para o fuso do aparelho. Datas sem offset são tratadas como locais.
  static DateTime? parseWall(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final DateTime? parsed = DateTime.tryParse(iso);
    if (parsed == null) return null;
    // Extrai o offset da string, se houver (ex.: -03:00, +00:00, Z).
    final RegExp offsetRe = RegExp(r'([+-])(\d{2}):?(\d{2})$');
    final Match? m = offsetRe.firstMatch(iso);
    Duration offset = Duration.zero;
    bool hasOffset = false;
    if (iso.endsWith('Z') || iso.endsWith('z')) {
      hasOffset = true;
    } else if (m != null) {
      hasOffset = true;
      final int sign = m.group(1) == '-' ? -1 : 1;
      offset = Duration(hours: int.parse(m.group(2)!), minutes: int.parse(m.group(3)!)) * sign;
    }
    if (!hasOffset) return parsed; // já é local
    final DateTime utc = parsed.toUtc().add(offset);
    return DateTime(utc.year, utc.month, utc.day, utc.hour, utc.minute, utc.second);
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// 14/07/2026
  static String date(String? iso) {
    final DateTime? d = parseWall(iso);
    if (d == null) return '—';
    return '${_two(d.day)}/${_two(d.month)}/${d.year}';
  }

  /// 14/07
  static String dayMonth(String? iso) {
    final DateTime? d = parseWall(iso);
    if (d == null) return '—';
    return '${_two(d.day)}/${_two(d.month)}';
  }

  /// 17 de julho
  static String dayMonthLong(String? iso) {
    final DateTime? d = parseWall(iso);
    if (d == null) return '—';
    return '${d.day} de ${_monthsLong[d.month - 1]}';
  }

  /// 17 de julho (a partir de DateTime).
  static String dayMonthLongOf(DateTime d) => '${d.day} de ${_monthsLong[d.month - 1]}';

  /// 17 de julho de 2026
  static String dateLong(String? iso) {
    final DateTime? d = parseWall(iso);
    if (d == null) return '—';
    return '${d.day} de ${_monthsLong[d.month - 1]} de ${d.year}';
  }

  /// 14/07/2026 às 23:59
  static String dateTime(String? iso) {
    final DateTime? d = parseWall(iso);
    if (d == null) return '—';
    return '${_two(d.day)}/${_two(d.month)}/${d.year} às ${_two(d.hour)}:${_two(d.minute)}';
  }

  /// 23:59
  static String time(String? iso) {
    final DateTime? d = parseWall(iso);
    if (d == null) return '—';
    return '${_two(d.hour)}:${_two(d.minute)}';
  }

  /// "jul" para uma data ISO.
  static String monthShort(String? iso) {
    final DateTime? d = parseWall(iso);
    if (d == null) return '—';
    return _monthsShort[d.month - 1];
  }

  /// "Jul" para um DateTime.
  static String monthShortOf(DateTime d) {
    final String s = _monthsShort[d.month - 1];
    return s[0].toUpperCase() + s.substring(1);
  }

  /// "seg" (DateTime.weekday: 1 = segunda).
  static String weekdayShort(DateTime d) => _weekdaysShort[d.weekday - 1];

  /// YYYY-MM-DD de uma data (usado pela rotina).
  static String isoDay(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

  /// "07:30" a partir de horas e minutos.
  static String hhmm(int hour, int minute) => '${_two(hour)}:${_two(minute)}';

  /// "250g - 25 doses" fica a cargo do título do produto; aqui só juntamos
  /// pedaços opcionais com " · ".
  static String join(List<String?> parts, [String sep = ' · ']) {
    return parts.where((p) => p != null && p.isNotEmpty).cast<String>().join(sep);
  }

  /// Distância até uma data futura, em texto curto ("em 12 dias", "hoje").
  static String relativeDays(String? iso, {DateTime? now}) {
    final DateTime? d = parseWall(iso);
    if (d == null) return '';
    final DateTime today = now ?? DateTime.now();
    final int days = DateTime(d.year, d.month, d.day).difference(DateTime(today.year, today.month, today.day)).inDays;
    if (days == 0) return 'hoje';
    if (days == 1) return 'amanhã';
    if (days == -1) return 'ontem';
    if (days > 1) return 'em $days dias';
    return 'há ${-days} dias';
  }

  /// Formata um nome de mês/ano "jul/2026".
  static String monthYear(String? iso) {
    final DateTime? d = parseWall(iso);
    if (d == null) return '—';
    return '${_monthsShort[d.month - 1]}/${d.year}';
  }
}
