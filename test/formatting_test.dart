import 'package:caffeine_prime/api/models/common.dart';
import 'package:caffeine_prime/core/formatting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fmt.money', () {
    test('formata em pt-BR', () {
      expect(Fmt.money(const Money(amount: 178.8)), 'R\$ 178,80');
      expect(Fmt.money(const Money(amount: 1234.5)), 'R\$ 1.234,50');
      expect(Fmt.money(const Money(amount: 0)), 'R\$ 0,00');
      expect(Fmt.money(null), '—');
    });
    test('inteiros e percentuais', () {
      expect(Fmt.integer(1580), '1.580');
      expect(Fmt.percent(15), '15%');
      expect(Fmt.percent(12.5), '12,5%');
    });
  });

  group('Fmt datas', () {
    test('preserva a hora de parede do offset de São Paulo', () {
      // 00:00 em São Paulo não pode virar o dia anterior/seguinte no aparelho.
      expect(Fmt.date('2026-07-14T00:00:00-03:00'), '14/07/2026');
      expect(Fmt.dayMonth('2026-07-14T00:00:00-03:00'), '14/07');
      expect(Fmt.dateTime('2026-07-14T23:59:00-03:00'), '14/07/2026 às 23:59');
      expect(Fmt.dayMonthLong('2026-07-17T00:00:00-03:00'), '17 de julho');
      expect(Fmt.dateLong('2023-08-12T00:00:00-03:00'), '12 de agosto de 2023');
      expect(Fmt.monthYear('2026-07-17T00:00:00-03:00'), 'jul/2026');
    });
    test('UTC e sem offset', () {
      expect(Fmt.date('2026-01-01T00:30:00Z'), '01/01/2026');
      expect(Fmt.date('2026-10-11'), '11/10/2026');
      expect(Fmt.date(null), '—');
      expect(Fmt.date('lixo'), '—');
    });
    test('relativeDays', () {
      final DateTime now = DateTime(2026, 7, 5);
      expect(Fmt.relativeDays('2026-07-17', now: now), 'em 12 dias');
      expect(Fmt.relativeDays('2026-07-05', now: now), 'hoje');
      expect(Fmt.relativeDays('2026-07-06', now: now), 'amanhã');
    });
    test('isoDay e hhmm', () {
      expect(Fmt.isoDay(DateTime(2026, 3, 9)), '2026-03-09');
      expect(Fmt.hhmm(7, 5), '07:05');
    });
  });
}
