import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../api/models/bills.dart';
import '../../../api/models/capabilities.dart';
import '../../../api/models/common.dart';
import '../../../api/models/dashboard.dart';
import '../../../api/models/subscription.dart';
import '../../../core/formatting.dart';
import '../../../core/widgets/alert_card.dart';
import '../../../core/widgets/prime_button.dart';
import '../../../router.dart';

/// Alertas do dashboard na ordem de prioridade: pagamento pendente, em análise,
/// pausada, cancelada, mudança agendada, rastreio, status desconhecido e
/// "por que não consigo editar".
class HomeAlerts extends StatelessWidget {
  const HomeAlerts({super.key, required this.dashboard, required this.onResume, required this.onReactivate});

  final Dashboard dashboard;
  final Future<void> Function() onResume;
  final Future<void> Function() onReactivate;

  @override
  Widget build(BuildContext context) {
    final List<Widget> cards = <Widget>[];
    final Subscription? s = dashboard.subscription;
    final Capabilities caps = dashboard.capabilities;

    // Pagamento pendente
    if (caps.hasPendingBill) {
      final PendingBillSummary? pb = caps.pendingBill;
      final String billId = pb?.id ?? dashboard.latestBill?.id ?? '';
      cards.add(AlertCard(
        tone: AlertTone.danger,
        icon: Icons.credit_card_off_rounded,
        title: 'Pagamento pendente',
        body: pb == null
            ? 'Não conseguimos cobrar sua última fatura. Regularize para receber sua caixa.'
            : 'Fatura de ${Fmt.money(pb.amount)} vencida em ${Fmt.date(pb.dueAt)}. '
                '${pb.pixAvailable ? 'Pague por PIX ou cartão.' : 'Pague com cartão.'}',
        actions: <Widget>[
          PrimeButton(
            label: 'Regularizar assinatura',
            expanded: false,
            small: true,
            onPressed: billId.isEmpty ? null : () async => context.push(Routes.payOf(billId)),
          ),
        ],
      ));
    }

    if (s != null) {
      // Status desconhecido (string livre da Prime API)
      if (s.rawStatus != null && s.rawStatus!.isNotEmpty) {
        cards.add(AlertCard(
          tone: AlertTone.neutral,
          title: 'Status: ${s.rawStatus}',
          body: 'Sua assinatura está em um estado que o app ainda não conhece. Se precisar, fale com a gente.',
        ));
      }

      switch (s.status) {
        case SubscriptionStatus.fraudReview:
          cards.add(const AlertCard(
            tone: AlertTone.info,
            icon: Icons.verified_user_outlined,
            title: 'Assinatura em análise',
            body: 'Sua primeira cobrança está em análise de segurança. Assim que for aprovada, liberamos o pedido.',
          ));
          break;
        case SubscriptionStatus.paused:
          final SubscriptionPause? p = s.pause;
          cards.add(AlertCard(
            tone: AlertTone.warning,
            title: 'Assinatura pausada',
            body: p == null
                ? 'Sua assinatura está pausada.'
                : 'Faltam ${p.remainingCycles} ciclo(s). Volta em ${Fmt.date(p.resumeAt)}. '
                    'Durante a pausa a fatura do ciclo vem em R\$ 0,00 — é esperado.',
            actions: <Widget>[
              if (caps.canResume.allowed)
                PrimeButton(label: 'Retomar assinatura', expanded: false, small: true, onPressed: onResume)
              else
                PrimeButton(
                  label: 'Ver detalhes',
                  expanded: false,
                  small: true,
                  variant: PrimeButtonVariant.secondary,
                  onPressed: () async => context.push(Routes.subscription),
                ),
            ],
          ));
          break;
        case SubscriptionStatus.canceled:
          cards.add(AlertCard(
            tone: AlertTone.neutral,
            icon: Icons.cancel_outlined,
            title: 'Assinatura cancelada',
            body: dashboard.lastCanceled == null
                ? 'Você pode reativar quando quiser.'
                : 'Cancelada em ${Fmt.date(dashboard.lastCanceled!.canceledAt)}.',
            actions: <Widget>[
              if (caps.canReactivate.allowed)
                PrimeButton(label: 'Reativar assinatura', expanded: false, small: true, onPressed: onReactivate),
            ],
          ));
          break;
        case SubscriptionStatus.future:
          cards.add(AlertCard(
            tone: AlertTone.info,
            title: 'Sua nova assinatura começa na próxima cobrança',
            body: 'Primeira cobrança em ${Fmt.date(s.nextBillingAt)}.',
          ));
          break;
        case SubscriptionStatus.active:
        case SubscriptionStatus.unknown:
          break;
      }

      // Mudança agendada
      final ScheduledChange? sc = s.scheduledChange;
      if (sc != null) {
        cards.add(AlertCard(
          tone: AlertTone.info,
          icon: Icons.event_repeat_rounded,
          title: 'Alteração de caixa agendada!',
          body: '${sc.nextCycleOnly ? 'Só no próximo ciclo' : 'A partir de ${Fmt.date(sc.appliesAt)}'}: '
              '${sc.items.length} item(ns) · ${Fmt.money(sc.total)}'
              '${sc.frequency != s.frequency ? ' · plano ${sc.frequency.label}' : ''}.',
          actions: <Widget>[
            PrimeButton(
              label: 'Editar caixa',
              expanded: false,
              small: true,
              variant: PrimeButtonVariant.dark,
              onPressed: () async => context.push(Routes.box),
            ),
          ],
        ));
      }

      // Janela de edição fechada
      final Capability edit = caps.canEdit;
      if (!edit.allowed && edit.reason == CapabilityReason.editWindowClosed) {
        cards.add(AlertCard(
          tone: AlertTone.neutral,
          title: 'Por que não consigo editar minha caixa agora?',
          body: 'Faltam poucos dias para a cobrança e sua caixa já está sendo preparada. '
              'A edição reabre em ${Fmt.date(edit.until)}.',
        ));
      }
    }

    // Rastreio
    final Fulfillment? t = dashboard.tracking;
    if (t != null && s != null) {
      cards.add(_trackingCard(context, t));
    }

    if (cards.isEmpty) return const SizedBox.shrink();
    return Column(
      children: <Widget>[
        for (int i = 0; i < cards.length; i++) ...<Widget>[
          cards[i],
          if (i < cards.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _trackingCard(BuildContext context, Fulfillment t) {
    String title;
    AlertTone tone = AlertTone.success;
    IconData icon = Icons.local_shipping_outlined;
    switch (t.status) {
      case FulfillmentStatus.pending:
      case FulfillmentStatus.processing:
        title = 'Caixa em preparo';
        tone = AlertTone.info;
        icon = Icons.inventory_outlined;
        break;
      case FulfillmentStatus.shipped:
      case FulfillmentStatus.inTransit:
        title = 'Caixa em trânsito!';
        break;
      case FulfillmentStatus.outForDelivery:
        title = 'Caixa saiu para entrega!';
        break;
      case FulfillmentStatus.delivered:
        title = 'Caixa entregue!';
        icon = Icons.check_circle_rounded;
        break;
      case FulfillmentStatus.failed:
        title = 'Problema na entrega';
        tone = AlertTone.danger;
        break;
      case FulfillmentStatus.unknown:
        title = 'Pedido: ${t.status.wire}';
        tone = AlertTone.neutral;
        break;
    }
    final String? eta = t.estimatedDeliveryAt;
    final String body = <String>[
      if (t.carrier != null) t.carrier!,
      if (t.trackingCode != null) 'Código ${t.trackingCode}',
      if (eta != null && t.status != FulfillmentStatus.delivered) 'Previsão ${Fmt.date(eta)}',
    ].join(' · ');
    return AlertCard(
      tone: tone,
      icon: icon,
      title: title,
      body: body.isEmpty ? null : body,
      onTap: () => context.push(Routes.orders),
    );
  }
}
