import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/models/capabilities.dart';
import '../../api/models/common.dart';
import '../../api/models/dashboard.dart';
import '../../api/models/subscription.dart';
import '../../core/formatting.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/capability_gate.dart';
import '../../core/widgets/prime_button.dart';
import '../../core/widgets/section_list.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/surface_card.dart';
import '../../data/providers.dart';
import '../../data/subscription_actions.dart';
import '../../router.dart';
import '../home/widgets/home_sections.dart';

/// "Meu plano": detalhes, vigência, timeline de fidelidade, desconto, pausa,
/// mudança agendada (com cancelar) e atalhos para pausar/cancelar.
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Dashboard> dashboard = ref.watch(dashboardProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Minha assinatura')),
      body: dashboard.when(
        loading: () => const LoadingView(),
        error: (Object e, _) => ErrorView(error: e, onRetry: () async => ref.invalidate(dashboardProvider)),
        data: (Dashboard d) {
          final Subscription? s = d.subscription;
          if (s == null) {
            return EmptyView(
              title: 'Sem assinatura',
              body: 'Você ainda não tem uma assinatura Prime.',
              action: PrimeButton(label: 'Saber mais', expanded: false, onPressed: () async => context.push(Routes.subscription)),
            );
          }
          final Capabilities caps = d.capabilities;
          return ListView(
            padding: const EdgeInsets.all(AppDims.pageMargin),
            children: <Widget>[
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        PlanBadge(frequency: s.frequency),
                        const Spacer(),
                        SubscriptionStatusBadge(subscription: s, hasPendingBill: caps.hasPendingBill),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(s.planName.isNotEmpty ? s.planName : 'Prime ${s.frequency.label}', style: AppTypography.h2),
                    const SizedBox(height: 8),
                    KeyValueRow(label: 'Assinante desde', value: Fmt.date(s.startedAt)),
                    KeyValueRow(label: 'Próxima cobrança', value: Fmt.dateLong(s.nextBillingAt)),
                    KeyValueRow(label: 'Ciclo atual', value: '${s.currentCycle}'),
                    KeyValueRow(label: 'Cobranças pagas', value: '${s.paidCycles}'),
                    KeyValueRow(label: 'Valor da caixa', value: Fmt.money(s.total)),
                    KeyValueRow(
                      label: 'Desconto',
                      value: Fmt.join(<String?>[
                        Fmt.percent(s.discount.temporaryPercentage ?? s.discount.percentage),
                        s.discount.temporaryCode ?? s.discount.code,
                        if (s.discount.temporaryCycles != null) 'por ${s.discount.temporaryCycles} ciclo(s)',
                      ]),
                    ),
                    KeyValueRow(label: 'Créditos de pausa', value: '${s.pauseCreditsLeft}'),
                    const SizedBox(height: 12),
                    CommitmentBar(subscription: s, canCancel: caps.canCancel),
                  ],
                ),
              ),
              const SizedBox(height: AppDims.sectionGap),
              const SectionTitle(title: 'Linha do tempo da fidelidade'),
              _CommitmentTimeline(subscription: s),
              if (s.scheduledChange != null) ...<Widget>[
                const SizedBox(height: AppDims.sectionGap),
                const SectionTitle(title: 'Mudança agendada'),
                _ScheduledChangeCard(change: s.scheduledChange!, current: s),
              ],
              const SizedBox(height: AppDims.sectionGap),
              const SectionTitle(title: 'Ações'),
              SectionListCard(
                children: <Widget>[
                  SectionRow(
                    icon: Icons.inventory_2_outlined,
                    title: 'Editar caixa',
                    subtitle: capabilityHint(caps.canEdit),
                    disabled: !caps.canEdit.allowed,
                    onTap: () => guardCapability(context, caps.canEdit, () => context.push(Routes.box), title: 'Edição da caixa'),
                  ),
                  if (s.status == SubscriptionStatus.active)
                    SectionRow(
                      icon: Icons.pause_circle_outline_rounded,
                      title: 'Pausar assinatura',
                      subtitle: capabilityHint(caps.canPause).isEmpty
                          ? 'Pule uma caixa usando um crédito de pausa'
                          : capabilityHint(caps.canPause),
                      disabled: !caps.canPause.allowed,
                      onTap: () => guardCapability(context, caps.canPause, () => context.push(Routes.pause), title: 'Pausa'),
                    ),
                  if (s.status == SubscriptionStatus.paused)
                    SectionRow(
                      icon: Icons.play_circle_outline_rounded,
                      title: 'Retomar assinatura',
                      subtitle: capabilityHint(caps.canResume),
                      disabled: !caps.canResume.allowed,
                      onTap: () => context.push(Routes.subscription),
                    ),
                  if (s.status != SubscriptionStatus.canceled)
                    SectionRow(
                      icon: Icons.highlight_off_rounded,
                      title: 'Cancelar e perder benefícios',
                      subtitle: capabilityHint(caps.canCancel),
                      danger: true,
                      onTap: () => guardCapability(context, caps.canCancel, () => context.push(Routes.cancel), title: 'Cancelamento'),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Timeline: próxima caixa + meses seguintes (previsão de 30 em 30 dias).
class _CommitmentTimeline extends StatelessWidget {
  const _CommitmentTimeline({required this.subscription});

  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    final DateTime? next = Fmt.parseWall(subscription.nextBillingAt);
    final int remaining = subscription.remainingCommitmentMonths;
    final int count = remaining > 0 ? remaining.clamp(1, 4).toInt() : 4;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              for (int i = 0; i < count; i++) ...<Widget>[
                Column(
                  children: <Widget>[
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == 0 ? AppColors.success : AppColors.successSoft,
                        border: Border.all(color: AppColors.success, width: 1.5),
                      ),
                      child: Icon(Icons.check, size: 12, color: i == 0 ? Colors.white : AppColors.success),
                    ),
                  ],
                ),
                if (i < count - 1) Expanded(child: Container(height: 2, color: AppColors.successSoft)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              for (int i = 0; i < count; i++)
                Expanded(
                  child: Text(
                    i == 0
                        ? 'Próxima caixa\n${next == null ? '—' : Fmt.dayMonthLongOf(next)}'
                        : 'Mês ${subscription.currentCycle + i}\n${next == null ? '' : 'prev. ${Fmt.monthShortOf(next.add(Duration(days: 30 * i)))}'}',
                    textAlign: i == 0 ? TextAlign.start : (i == count - 1 ? TextAlign.end : TextAlign.center),
                    style: AppTypography.caption,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            remaining > 0
                ? 'Restam $remaining ${remaining == 1 ? 'mês' : 'meses'} de fidelidade. As datas após a próxima são previsão (ciclo de 30 dias).'
                : remaining == 0
                    ? 'Fidelidade cumprida. Sem cancelar, a assinatura renova normalmente.'
                    : 'Plano sem fidelidade.',
            style: AppTypography.small,
          ),
        ],
      ),
    );
  }
}

class _ScheduledChangeCard extends ConsumerWidget {
  const _ScheduledChangeCard({required this.change, required this.current});

  final ScheduledChange change;
  final Subscription current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.event_repeat_rounded, color: AppColors.info),
              const SizedBox(width: 8),
              Expanded(child: Text('Vale a partir de ${Fmt.date(change.appliesAt)}', style: AppTypography.bodyBold)),
              if (change.nextCycleOnly) const StatusBadge(label: 'SÓ PRÓXIMA CAIXA', tone: BadgeTone.info),
            ],
          ),
          const SizedBox(height: 8),
          if (change.frequency != current.frequency)
            KeyValueRow(label: 'Novo plano', value: change.planName.isNotEmpty ? change.planName : change.frequency.label),
          KeyValueRow(label: 'Itens', value: '${change.items.length}'),
          KeyValueRow(label: 'Novo valor', value: Fmt.money(change.total)),
          const SizedBox(height: 6),
          for (final ProductItem i in change.items)
            Text('• ${i.quantity}x ${i.title}${i.flavor != null ? ' (${i.flavor})' : ''}', style: AppTypography.small),
          const SizedBox(height: 12),
          PrimeButton(
            label: 'Desfazer alteração agendada',
            variant: PrimeButtonVariant.danger,
            onPressed: () async {
              final bool? ok = await showDialog<bool>(
                context: context,
                builder: (BuildContext ctx) => AlertDialog(
                  title: const Text('Desfazer alteração?'),
                  content: const Text('Sua caixa volta ao que era antes. Se houve troca de plano, a assinatura original é reativada.'),
                  actions: <Widget>[
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Manter')),
                    TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Desfazer')),
                  ],
                ),
              );
              if (ok != true) return;
              try {
                await ref.read(subscriptionActionsProvider).cancelScheduling();
                if (context.mounted) showSuccessToast(context, 'Alteração desfeita');
              } catch (e) {
                if (context.mounted) showErrorToast(context, e);
              }
            },
          ),
        ],
      ),
    );
  }
}
