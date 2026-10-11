import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/models/bills.dart';
import '../../api/models/common.dart';
import '../../core/formatting.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/surface_card.dart';
import '../../data/providers.dart';
import '../../router.dart';

/// Lista de pedidos/faturas (GET /me/bills). Fatura de ciclo pausado (R$ 0,00)
/// aparece como "Ciclo pausado", não como erro.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Bill>> bills = ref.watch(billsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Meus pedidos')),
      body: bills.when(
        loading: () => const LoadingView(),
        error: (Object e, _) => ErrorView(error: e, onRetry: () async => ref.invalidate(billsProvider)),
        data: (List<Bill> list) {
          if (list.isEmpty) {
            return const EmptyView(title: 'Nenhum pedido ainda', body: 'Seus pedidos aparecem aqui a cada ciclo.');
          }
          final List<Bill> sorted = List<Bill>.from(list)..sort((a, b) => b.cycle.compareTo(a.cycle));
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(billsProvider);
              await ref.read(billsProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(AppDims.pageMargin),
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (BuildContext context, int i) => BillTile(bill: sorted[i]),
            ),
          );
        },
      ),
    );
  }
}

class BillTile extends StatelessWidget {
  const BillTile({super.key, required this.bill});

  final Bill bill;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push(Routes.orderDetailOf(bill.id)),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: AppColors.bgSubtle, shape: BoxShape.circle),
            child: Icon(_icon(bill), color: AppColors.brandGold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Ciclo ${bill.cycle} · ${Fmt.monthYear(bill.issuedAt)}', style: AppTypography.bodyBold),
                Text(
                  bill.isPausedCycle
                      ? 'Ciclo pausado'
                      : '${bill.items.length} ${bill.items.length == 1 ? 'item' : 'itens'} · ${Fmt.money(bill.amount)}',
                  style: AppTypography.small,
                ),
                if (bill.fulfillment != null)
                  Text(bill.fulfillment!.status.label, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          billStatusBadge(bill),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }

  static IconData _icon(Bill b) {
    if (b.isPausedCycle) return Icons.pause_rounded;
    switch (b.fulfillment?.status) {
      case FulfillmentStatus.delivered:
        return Icons.check_circle_outline_rounded;
      case FulfillmentStatus.inTransit:
      case FulfillmentStatus.shipped:
      case FulfillmentStatus.outForDelivery:
        return Icons.local_shipping_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }
}

Widget billStatusBadge(Bill bill) {
  if (bill.isPausedCycle) return const StatusBadge(label: 'PAUSADO', tone: BadgeTone.warning);
  switch (bill.status) {
    case BillStatus.paid:
      return const StatusBadge(label: 'PAGO', tone: BadgeTone.success);
    case BillStatus.pending:
      return const StatusBadge(label: 'PENDENTE', tone: BadgeTone.danger);
    case BillStatus.canceled:
      return const StatusBadge(label: 'CANCELADO', tone: BadgeTone.neutral);
    case BillStatus.review:
      return const StatusBadge(label: 'EM ANÁLISE', tone: BadgeTone.info);
    case BillStatus.unknown:
      return const StatusBadge(label: 'STATUS ?', tone: BadgeTone.neutral);
  }
}
