import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/models/bills.dart';
import '../../api/models/common.dart';
import '../../api/models/subscription.dart';
import '../../core/formatting.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/prime_button.dart';
import '../../core/widgets/product_thumb.dart';
import '../../core/widgets/section_list.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/surface_card.dart';
import '../../data/providers.dart';
import '../../router.dart';
import 'orders_screen.dart';

/// Detalhe da fatura/pedido com itens, pagamento e timeline de rastreio.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.billId});

  final String billId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Bill> bill = ref.watch(billProvider(billId));
    return Scaffold(
      appBar: AppBar(title: const Text('Pedido')),
      body: bill.when(
        loading: () => const LoadingView(),
        error: (Object e, _) => ErrorView(error: e, onRetry: () async => ref.invalidate(billProvider(billId))),
        data: (Bill b) => ListView(
          padding: const EdgeInsets.all(AppDims.pageMargin),
          children: <Widget>[
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(child: Text('Ciclo ${b.cycle}', style: AppTypography.h2)),
                      billStatusBadge(b),
                    ],
                  ),
                  const SizedBox(height: 8),
                  KeyValueRow(label: 'Emitida em', value: Fmt.date(b.issuedAt)),
                  KeyValueRow(label: 'Vencimento', value: Fmt.date(b.dueAt)),
                  if (b.paidAt != null) KeyValueRow(label: 'Paga em', value: Fmt.date(b.paidAt)),
                  KeyValueRow(label: 'Valor', value: Fmt.money(b.amount)),
                  if (b.paymentMethod != null)
                    KeyValueRow(
                      label: 'Pagamento',
                      value: b.paymentMethod == PaymentMethod.pix
                          ? 'PIX'
                          : b.paymentProfile != null
                              ? '${b.paymentProfile!.brand} •••• ${b.paymentProfile!.lastFour}'
                              : 'Cartão',
                    ),
                  if (b.isPausedCycle) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      'Ciclo pausado: durante a pausa a fatura vem em R\$ 0,00. É esperado, não é cobrança.',
                      style: AppTypography.small.copyWith(color: AppColors.warningText),
                    ),
                  ],
                  if (b.status == BillStatus.pending) ...<Widget>[
                    const SizedBox(height: 12),
                    PrimeButton(label: 'Pagar agora', onPressed: () async => context.push(Routes.payOf(b.id))),
                  ],
                ],
              ),
            ),
            if (b.items.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppDims.sectionGap),
              const SectionTitle(title: 'Itens da caixa'),
              SurfaceCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: <Widget>[
                    for (final ProductItem i in b.items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: <Widget>[
                            ProductThumb(imageUrl: i.imageUrl, handle: i.handle, title: i.title, flavor: i.flavor, size: 48, quantity: i.quantity),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(i.title, style: AppTypography.bodyBold),
                                  Text(Fmt.join(<String?>[i.flavor, i.gift ? 'Brinde' : null]), style: AppTypography.small),
                                ],
                              ),
                            ),
                            Text(i.gift ? 'Grátis' : Fmt.money(i.finalPrice), style: AppTypography.bodyBold),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (b.fulfillment != null) ...<Widget>[
              const SizedBox(height: AppDims.sectionGap),
              const SectionTitle(title: 'Rastreio'),
              TrackingTimeline(fulfillment: b.fulfillment!),
            ],
          ],
        ),
      ),
    );
  }
}

/// Timeline vertical do rastreio (etapas padrão + eventos da transportadora).
class TrackingTimeline extends StatelessWidget {
  const TrackingTimeline({super.key, required this.fulfillment});

  final Fulfillment fulfillment;

  static const List<FulfillmentStatus> _steps = <FulfillmentStatus>[
    FulfillmentStatus.processing,
    FulfillmentStatus.shipped,
    FulfillmentStatus.inTransit,
    FulfillmentStatus.outForDelivery,
    FulfillmentStatus.delivered,
  ];

  int _indexOf(FulfillmentStatus s) {
    switch (s) {
      case FulfillmentStatus.pending:
      case FulfillmentStatus.processing:
        return 0;
      case FulfillmentStatus.shipped:
        return 1;
      case FulfillmentStatus.inTransit:
        return 2;
      case FulfillmentStatus.outForDelivery:
        return 3;
      case FulfillmentStatus.delivered:
        return 4;
      case FulfillmentStatus.failed:
      case FulfillmentStatus.unknown:
        return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int current = _indexOf(fulfillment.status);
    final bool failed = fulfillment.status == FulfillmentStatus.failed;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  failed ? 'Problema na entrega' : fulfillment.status.label,
                  style: AppTypography.h3.copyWith(color: failed ? AppColors.danger : null),
                ),
              ),
              if (fulfillment.estimatedDeliveryAt != null && fulfillment.status != FulfillmentStatus.delivered)
                Text('Previsão ${Fmt.date(fulfillment.estimatedDeliveryAt)}', style: AppTypography.small),
            ],
          ),
          if (fulfillment.carrier != null || fulfillment.trackingCode != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                Fmt.join(<String?>[fulfillment.carrier, fulfillment.trackingCode]),
                style: AppTypography.small,
              ),
            ),
          const SizedBox(height: 16),
          if (!failed && current >= 0)
            Row(
              children: <Widget>[
                for (int i = 0; i < _steps.length; i++) ...<Widget>[
                  _Dot(done: i <= current, active: i == current),
                  if (i < _steps.length - 1)
                    Expanded(child: Container(height: 2, color: i < current ? AppColors.success : AppColors.bgMuted)),
                ],
              ],
            ),
          if (!failed && current >= 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: _steps
                    .map((s) => Expanded(
                          child: Text(
                            s.label,
                            textAlign: TextAlign.center,
                            style: AppTypography.caption.copyWith(fontSize: 9),
                          ),
                        ))
                    .toList(),
              ),
            ),
          if (fulfillment.events.isNotEmpty) ...<Widget>[
            const Divider(height: 24),
            for (final TrackingEvent e in fulfillment.events.reversed)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.circle, size: 8, color: AppColors.brandGold),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(e.description, style: AppTypography.smallBold),
                          Text(
                            Fmt.join(<String?>[Fmt.dateTime(e.occurredAt), e.location]),
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (fulfillment.trackingUrl != null) ...<Widget>[
            const SizedBox(height: 8),
            PrimeButton(
              label: 'Abrir rastreio da transportadora',
              variant: PrimeButtonVariant.secondary,
              icon: Icons.open_in_new_rounded,
              onPressed: () async {
                final Uri? u = Uri.tryParse(fulfillment.trackingUrl!);
                if (u != null) await launchUrl(u, mode: LaunchMode.externalApplication);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.done, required this.active});

  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? AppColors.success : AppColors.bgMuted,
        border: active ? Border.all(color: AppColors.successDeep, width: 2) : null,
      ),
      child: done ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
    );
  }
}
