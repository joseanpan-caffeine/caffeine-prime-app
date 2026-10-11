import 'package:caffeine_prime/core/utils/idempotency.dart';
import 'package:caffeine_prime/core/utils/streak.dart';
import 'package:caffeine_prime/core/deep_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StreakHelper', () {
    const List<DayCompletion> days = <DayCompletion>[
      DayCompletion('2026-10-05', 1),
      DayCompletion('2026-10-06', 1),
      DayCompletion('2026-10-07', 0),
      DayCompletion('2026-10-08', 1),
      DayCompletion('2026-10-09', 1),
      DayCompletion('2026-10-10', 1),
      DayCompletion('2026-10-11', 0.5), // hoje, incompleto
    ];
    test('sequência atual ignora hoje incompleto', () {
      expect(StreakHelper.currentStreak(days), 3);
      expect(StreakHelper.currentStreak(days, todayPending: false), 0);
    });
    test('maior sequência', () {
      expect(StreakHelper.longestStreak(days), 3);
      expect(StreakHelper.longestStreak(const <DayCompletion>[]), 0);
    });
    test('parseHhMm', () {
      expect(StreakHelper.parseHhMm('07:30'), (hour: 7, minute: 30));
      expect(StreakHelper.parseHhMm('25:00'), isNull);
      expect(StreakHelper.parseHhMm('x'), isNull);
      expect(StreakHelper.parseHhMm(null), isNull);
    });
    test('notificationId estável e positivo', () {
      expect(StreakHelper.notificationId('abc'), StreakHelper.notificationId('abc'));
      expect(StreakHelper.notificationId('abc'), greaterThan(0));
      expect(StreakHelper.notificationId('abc') == StreakHelper.notificationId('abd'), false);
    });
  });

  group('uuidV4', () {
    test('formato e unicidade', () {
      final String a = uuidV4();
      final String b = uuidV4();
      expect(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$').hasMatch(a), true);
      expect(a == b, false);
    });
  });

  group('DeepLinks', () {
    test('mapeia esquemas e destinos', () {
      expect(DeepLinks.routeFor(Uri.parse('app://box')), '/box');
      expect(DeepLinks.routeFor(Uri.parse('app://routine?item=r1')), '/routine?item=r1');
      expect(DeepLinks.routeFor(Uri.parse('app://pay/bill_1')), '/pay/bill_1');
      expect(DeepLinks.routeFor(Uri.parse('caffeineprime://auth/magic/abc.def')), '/auth/magic/abc.def');
      expect(DeepLinks.routeFor(Uri.parse('https://www.caffeinearmy.com.br/account/prime/orders')), '/orders');
      expect(DeepLinks.routeFor(Uri.parse('app://whatever')), '/home');
      expect(DeepLinks.routeFor(Uri.parse('mailto:x@y')), isNull);
      expect(DeepLinks.routeForString('/cards'), '/cards');
      expect(DeepLinks.routeForString(null), isNull);
    });
  });
}
