import 'dart:convert';

import 'package:caffeine_prime/api/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Round-trip fromJson/toJson com JSON de exemplo no formato do contrato (api.ts).
void main() {
  group('Dashboard', () {
    const String sample = '''
    {
      "user": {"id": "7788", "email": "ativa@teste.com", "firstName": "Brenda", "lastName": "Leal",
               "cpf": "***.***.123-45", "hasSubscription": true},
      "subscription": {
        "id": "sub_1", "status": "active", "frequency": "Anual", "planName": "Prime Anual",
        "startedAt": "2023-08-12T00:00:00-03:00", "nextBillingAt": "2026-07-17T00:00:00-03:00",
        "currentCycle": 5, "paidCycles": 4, "remainingCommitmentMonths": 8, "pauseCreditsLeft": 2,
        "items": [
          {"id": "i1", "handle": "supercoffee-original-economic-size", "title": "SuperCoffee Original 380g",
           "flavor": "Original", "quantity": 2, "price": {"amount": 184.9, "currency": "BRL"},
           "discountPercentage": 15, "finalPrice": {"amount": 157.17, "currency": "BRL"}, "recurrence": null},
          {"id": "i2", "handle": "morning-shot-limao-stick", "title": "Morning Shot Limão", "quantity": 1,
           "price": {"amount": 89.9, "currency": "BRL"}, "discountPercentage": 15,
           "finalPrice": {"amount": 76.42, "currency": "BRL"}, "recurrence": "on", "cyclesLeft": 2, "isGift": false}
        ],
        "discount": {"code": "PRIME15", "percentage": 15},
        "paymentProfile": {"id": "pp1", "brand": "Mastercard", "lastFour": "4321", "holderName": "BRENDA LEAL",
                           "expiration": "12/2028", "isDefault": true},
        "shippingAddress": {"id": "a1", "recipient": "Brenda", "postalCode": "01310100", "street": "Av. Paulista",
                            "number": "1000", "neighborhood": "Bela Vista", "city": "São Paulo", "state": "SP"},
        "scheduledChange": {"id": "sc1", "appliesAt": "2026-07-17T00:00:00-03:00", "frequency": "Anual",
                            "planName": "Prime Anual", "items": [], "total": {"amount": 390.49, "currency": "BRL"},
                            "nextCycleOnly": true},
        "subtotal": {"amount": 459.7, "currency": "BRL"}, "totalDiscount": {"amount": 68.94, "currency": "BRL"},
        "total": {"amount": 390.76, "currency": "BRL"}
      },
      "capabilities": {
        "canEdit": {"allowed": true, "closesAt": "2026-07-14T00:00:00-03:00"},
        "canPause": {"allowed": true, "creditsLeft": 2, "maxCycles": 2, "closesAt": "2026-07-14T00:00:00-03:00"},
        "canResume": {"allowed": false, "reason": "NOT_PAUSED"},
        "canCancel": {"allowed": false, "reason": "COMMITMENT_ACTIVE", "remainingCommitmentMonths": 8,
                      "until": "2027-03-17T00:00:00-03:00", "commitmentEndsAt": "2027-03-17T00:00:00-03:00"},
        "canReactivate": {"allowed": false, "reason": "NOT_CANCELED"},
        "canChangeCard": {"allowed": true},
        "canChangeAddress": {"allowed": true},
        "hasPendingBill": false
      },
      "tracking": {"status": "in_transit", "carrier": "Correios", "trackingCode": "BR123",
                   "events": [{"status": "12", "description": "Em trânsito", "occurredAt": "2026-07-01T10:00:00-03:00"}]},
      "savings": {"last12Months": {"amount": 820.5, "currency": "BRL"}, "sinceStart": {"amount": 2410.9, "currency": "BRL"}},
      "wallet": {"points": 1580, "label": "pontos"},
      "banners": [{"id": "b1", "title": "Prime Week", "deepLink": "app://box"}]
    }
    ''';

    test('fromJson lê todos os campos do contrato', () {
      final Dashboard d = Dashboard.fromJson(jsonDecode(sample) as Map<String, dynamic>);
      expect(d.user.id, '7788');
      expect(d.subscription, isNotNull);
      final Subscription s = d.subscription!;
      expect(s.status, SubscriptionStatus.active);
      expect(s.frequency, Frequency.anual);
      expect(s.items.length, 2);
      expect(s.items[0].recurrence, ItemRecurrence.everyCycle);
      expect(s.items[1].recurrence, ItemRecurrence.on);
      expect(s.items[1].cyclesLeft, 2);
      expect(s.paymentProfile!.lastFour, '4321');
      expect(s.scheduledChange!.nextCycleOnly, true);
      expect(d.capabilities.canCancel.reason, CapabilityReason.commitmentActive);
      expect(d.capabilities.canCancel.commitmentEndsAt, isNotNull);
      expect(d.capabilities.canPause.creditsLeft, 2);
      expect(d.tracking!.status, FulfillmentStatus.inTransit);
      expect(d.savings.sinceStart.amount, 2410.9);
      expect(d.wallet.points, 1580);
      expect(d.banners.single.deepLink, 'app://box');
    });

    test('toJson → fromJson preserva os valores', () {
      final Dashboard d = Dashboard.fromJson(jsonDecode(sample) as Map<String, dynamic>);
      final Dashboard again = Dashboard.fromJson(jsonDecode(jsonEncode(d.toJson())) as Map<String, dynamic>);
      expect(again.subscription!.total, d.subscription!.total);
      expect(again.subscription!.items[1].recurrence, ItemRecurrence.on);
      // recurrence null (todo ciclo) precisa continuar como chave presente/nula
      expect(d.subscription!.items[0].toJson().containsKey('recurrence'), true);
      expect(d.subscription!.items[0].toJson()['recurrence'], isNull);
      expect(again.capabilities.canCancel.until, d.capabilities.canCancel.until);
    });

    test('status desconhecido e campos faltando não quebram', () {
      final Subscription s = Subscription.fromJson(<String, dynamic>{
        'id': 'x',
        'status': 'weird_status',
        'rawStatus': 'weird_status',
        'frequency': 'Bienal',
      });
      expect(s.status, SubscriptionStatus.unknown);
      expect(s.frequency, Frequency.unknown);
      expect(s.hasUnknownStatus, true);
      expect(s.items, isEmpty);
      expect(s.total, Money.zero);
      expect(CapabilityReason.parseOrNull('SOMETHING_NEW'), CapabilityReason.unknown);
      expect(Capabilities.fromJson(null).canEdit.allowed, false);
    });
  });

  group('Bill', () {
    test('fatura pendente com PIX e ciclo pausado', () {
      final Bill b = Bill.fromJson(<String, dynamic>{
        'id': 'bill_1',
        'cycle': 6,
        'status': 'pending',
        'issuedAt': '2026-07-17T00:00:00-03:00',
        'dueAt': '2026-07-20T00:00:00-03:00',
        'amount': <String, dynamic>{'amount': 178.8, 'currency': 'BRL'},
        'paymentMethod': 'pix',
        'pix': <String, dynamic>{'qrCodeImageUrl': 'https://x/qr.png', 'qrCodeText': '0002012636...', 'expiresAt': '2026-07-18T00:00:00-03:00'},
        'items': <dynamic>[],
        'pausedCycle': true,
      });
      expect(b.status, BillStatus.pending);
      expect(b.paymentMethod, PaymentMethod.pix);
      expect(b.pix!.qrCodeText, startsWith('0002'));
      expect(b.isPausedCycle, true);
      final Bill again = Bill.fromJson(b.toJson());
      expect(again.pix!.expiresAt, b.pix!.expiresAt);
      expect(again.amount.amount, 178.8);
    });
  });

  group('RoutineSummary', () {
    test('fromJson + toJson', () {
      final RoutineSummary s = RoutineSummary.fromJson(<String, dynamic>{
        'today': <String, dynamic>{
          'date': '2026-10-11',
          'items': <dynamic>[
            <String, dynamic>{'routineItemId': 'r1', 'done': true},
            <String, dynamic>{'routineItemId': 'r2', 'done': false},
          ],
          'completion': 0.5,
        },
        'currentStreakDays': 4,
        'longestStreakDays': 12,
        'weekCompletion': 0.71,
        'last28Days': <dynamic>[
          <String, dynamic>{'date': '2026-10-10', 'completion': 1},
          <String, dynamic>{'date': '2026-10-11', 'completion': 0.5},
        ],
        'stockForecast': <dynamic>[
          <String, dynamic>{'productHandle': 'supercoffee-original-economic-size', 'dosesLeft': 12, 'runsOutAt': '2026-10-23', 'nextBoxAt': '2026-10-20'},
        ],
      });
      expect(s.today.isDone('r1'), true);
      expect(s.today.isDone('r2'), false);
      expect(s.currentStreakDays, 4);
      expect(s.last28Days.length, 2);
      expect(s.stockForecast!.single.dosesLeft, 12);
      final RoutineSummary again = RoutineSummary.fromJson(s.toJson());
      expect(again.weekCompletion, 0.71);
      expect(again.stockForecast!.single.runsOutAt, '2026-10-23');
    });

    test('RoutinePlan e update request', () {
      final RoutinePlan p = RoutinePlan.fromJson(<String, dynamic>{
        'items': <dynamic>[
          <String, dynamic>{
            'id': 'r1', 'productHandle': 'morning-shot-limao-stick', 'title': 'Morning Shot', 'slot': 'pre_workout',
            'reminderTime': '17:00', 'reminderEnabled': true, 'dosesPerDay': 1, 'usageHint': 'Tome 30 min antes do treino',
          },
        ],
        'weeklyGoalDays': 9,
        'timezone': 'America/Sao_Paulo',
      });
      expect(p.weeklyGoalDays, 7); // clamp 1–7
      expect(p.items.single.slot, RoutineSlot.preWorkout);
      final Map<String, dynamic> upd = UpdateRoutinePlanRequest(items: p.items).toJson();
      final Map<String, dynamic> item = (upd['items'] as List<dynamic>).first as Map<String, dynamic>;
      expect(item.containsKey('title'), false);
      expect(item.containsKey('usageHint'), false);
      expect(item['reminderTime'], '17:00');
    });
  });

  group('Consentimentos e config', () {
    test('AppConfig parse de features e versões', () {
      final AppConfig c = AppConfig.fromJson(<String, dynamic>{
        'minSupportedVersion': '1.0.0',
        'features': <String, dynamic>{'routine': true, 'assistant': 'false'},
        'links': <String, dynamic>{'privacy': 'p', 'terms': 't', 'support': 's', 'subscribeUrl': 'u'},
        'consentVersions': <String, dynamic>{'health_data': '2', 'bogus': '9'},
      });
      expect(c.feature('routine'), true);
      expect(c.feature('assistant'), false);
      expect(c.feature('health'), true); // fallback
      expect(c.consentVersion(ConsentKind.healthData), '2');
      expect(c.consentVersion(ConsentKind.push), '1');
      expect(ConsentKind.parse('bogus'), ConsentKind.unknown);
    });
  });
}
