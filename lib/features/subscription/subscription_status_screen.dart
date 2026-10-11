import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/models/capabilities.dart';
import '../../api/models/common.dart';
import '../../api/models/dashboard.dart';
import '../../api/models/subscription.dart';
import '../../core/formatting.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/alert_card.dart';
import '../../core/widgets/capability_gate.dart';
import '../../core/widgets/prime_button.dart';
import '../../core/widgets/section_list.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/surface_card.dart';
import '../../data/providers.dart';
import '../../data/subscription_actions.dart';
import '../../router.dart';

/// Estados especiais da assinatura: pausada, cancelada, em análise, sem
/// assinatura, status desconhecido. Ações: retomar / reativar / assinar.
class SubscriptionStatusScreen extends ConsumerWidget {
  const SubscriptionStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Dashboard> dashboard = ref.watch(dashboardProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Status da assinatura')),
      body: dashboard.when(
        loading: () => const LoadingView(),
        error: (Object e, _) => ErrorView(error: e, onRetry: () async => ref.invalidate(dashboardProvider)),
        data: (Dashboard d) => ListView(
          padding: const EdgeInsets.all(AppDims.pageMargin),
          children: <Widget>[_content(context, ref, d)],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, Dashboard d) {
    final Subscription? s = d.subscription;
    final Capabilities caps = d.capabilities;
    if (s == null) return _NoSubscription(dashboard: d);

    if ((s.rawStatus != null && s.rawStatus!.isNotEmpty) || s.status == SubscriptionStatus.unknown) {
      return _StatusCard(
        icon: Icons.help_outline_rounded,
        color: AppColors.textSecondary,
        title: 'Status: ${s.rawStatus ?? 'desconhecido'}',
        body: 'Sua assinatura está em um estado que o app ainda não reconhece. Nada foi perdido; '
            'se precisar fazer alguma alteração, fale com o atendimento.',
        rows: <Widget>[
          KeyValueRow(label: 'Plano', value: s.frequency.label),
          KeyValueRow(label: 'Próxima cobrança', value: Fmt.date(s.nextBillingAt)),
        ],
        actions: <Widget>[_supportButton(ref)],
      );
    }

    switch (s.status) {
      case SubscriptionStatus.paused:
        final SubscriptionPause? p = s.pause;
        return _StatusCard(
          icon: Icons.pause_circle_filled_rounded,
          color: AppColors.warningText,
          title: 'Assinatura pausada',
          body: p == null
              ? 'Sua assinatura está pausada.'
              : 'Pausada em ${Fmt.date(p.pausedAt)} por ${p.cycles} ciclo(s); faltam ${p.remainingCycles}. '
                  'Volta em ${Fmt.date(p.resumeAt)}.${p.pauseType == PauseType.offer ? ' Pausa oferecida pelo atendimento (não usa crédito).' : ''}',
          rows: <Widget>[
            KeyValueRow(label: 'Créditos de pausa restantes', value: '${s.pauseCreditsLeft}'),
            KeyValueRow(label: 'Próxima cobrança', value: Fmt.date(s.nextBillingAt)),
          ],
          note: 'Durante a pausa, cada ciclo gera uma fatura de R\$ 0,00 — é esperado, não é cobrança.',
          actions: <Widget>[
            PrimeButton(
              label: 'Retomar assinatura',
              onPressed: () async => guardCapability(context, caps.canResume, () => _resume(context, ref), title: 'Retomar'),
            ),
            if (!caps.canResume.allowed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(capabilityHint(caps.canResume), style: AppTypography.caption, textAlign: TextAlign.center),
              )
            else if (caps.canResume.closesAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Você pode desfazer a pausa até ${Fmt.dateTime(caps.canResume.closesAt)}.', style: AppTypography.caption, textAlign: TextAlign.center),
              ),
          ],
        );
      case SubscriptionStatus.canceled:
        return _StatusCard(
          icon: Icons.cancel_rounded,
          color: AppColors.textMuted,
          title: 'Assinatura cancelada',
          body: d.lastCanceled == null
              ? 'Sua assinatura foi cancelada.'
              : 'Cancelada em ${Fmt.date(d.lastCanceled!.canceledAt)}${d.lastCanceled!.reason != null ? ' · motivo: ${d.lastCanceled!.reason}' : ''}.',
          rows: <Widget>[KeyValueRow(label: 'Plano', value: s.frequency.label)],
          actions: <Widget>[
            PrimeButton(
              label: 'Reativar assinatura',
              onPressed: () async => guardCapability(context, caps.canReactivate, () => _reactivate(context, ref), title: 'Reativar'),
            ),
            if (!caps.canReactivate.allowed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(capabilityHint(caps.canReactivate), style: AppTypography.caption, textAlign: TextAlign.center),
              ),
          ],
        );
      case SubscriptionStatus.fraudReview:
        return _StatusCard(
          icon: Icons.verified_user_rounded,
          color: AppColors.info,
          title: 'Assinatura em análise',
          body: 'Sua primeira cobrança está em análise de segurança (antifraude). Costuma ser rápido. '
              'Assim que aprovada, liberamos o pedido e você recebe um e-mail.',
          rows: <Widget>[KeyValueRow(label: 'Plano', value: s.frequency.label)],
          actions: <Widget>[_supportButton(ref)],
        );
      case SubscriptionStatus.future:
        return _StatusCard(
          icon: Icons.schedule_rounded,
          color: AppColors.info,
          title: 'Começa na próxima cobrança',
          body: 'Sua nova assinatura entra em vigor em ${Fmt.date(s.nextBillingAt)}.',
          rows: <Widget>[KeyValueRow(label: 'Plano', value: s.frequency.label)],
          actions: <Widget>[
            PrimeButton(label: 'Ver meu plano', variant: PrimeButtonVariant.secondary, onPressed: () async => context.push(Routes.plan)),
          ],
        );
      case SubscriptionStatus.active:
      case SubscriptionStatus.unknown:
        return _StatusCard(
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
          title: 'Assinatura ativa',
          body: 'Tudo certo com sua assinatura.',
          rows: <Widget>[
            KeyValueRow(label: 'Plano', value: s.frequency.label),
            KeyValueRow(label: 'Próxima cobrança', value: Fmt.date(s.nextBillingAt)),
          ],
          actions: <Widget>[
            PrimeButton(label: 'Ver meu plano', variant: PrimeButtonVariant.secondary, onPressed: () async => context.push(Routes.plan)),
          ],
        );
    }
  }

  Widget _supportButton(WidgetRef ref) {
    return PrimeButton(
      label: 'Fale conosco',
      variant: PrimeButtonVariant.secondary,
      onPressed: () async {
        final Uri? u = Uri.tryParse(ref.read(appConfigValueProvider).links.support);
        if (u != null) await launchUrl(u, mode: LaunchMode.externalApplication);
      },
    );
  }

  Future<void> _resume(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(subscriptionActionsProvider).resume();
      if (context.mounted) showSuccessToast(context, 'Assinatura retomada', body: 'Os créditos dos ciclos não pausados voltam para você.');
    } catch (e) {
      if (context.mounted) showErrorToast(context, e);
    }
  }

  Future<void> _reactivate(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(subscriptionActionsProvider).reactivate();
      if (context.mounted) showSuccessToast(context, 'Assinatura reativada', body: 'Bem-vindo de volta!');
    } catch (e) {
      if (context.mounted) showErrorToast(context, e);
    }
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    this.rows = const <Widget>[],
    this.actions = const <Widget>[],
    this.note,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final List<Widget> rows;
  final List<Widget> actions;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, color: color, size: 40),
              const SizedBox(height: 12),
              Text(title, style: AppTypography.h2),
              const SizedBox(height: 6),
              Text(body, style: AppTypography.body),
              if (rows.isNotEmpty) ...<Widget>[const Divider(height: 24), ...rows],
              if (note != null) ...<Widget>[
                const SizedBox(height: 12),
                AlertCard(tone: AlertTone.neutral, title: 'Bom saber', body: note),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...actions,
      ],
    );
  }
}

class _NoSubscription extends ConsumerWidget {
  const _NoSubscription({required this.dashboard});

  final Dashboard dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String url = ref.watch(appConfigValueProvider).links.subscribeUrl;
    return _StatusCard(
      icon: Icons.inventory_2_outlined,
      color: AppColors.brandGold,
      title: 'Você ainda não é Prime',
      body: 'Monte sua caixa com SuperCoffee, Morning Shot, Koala e Labs, receba a cada 30 dias com desconto, '
          'frete grátis, pontos no Caffeine Army X e brindes exclusivos.',
      actions: <Widget>[
        PrimeButton(
          label: 'Assinar o Prime',
          icon: Icons.open_in_new_rounded,
          onPressed: () async {
            final Uri? u = Uri.tryParse(url);
            if (u != null) await launchUrl(u, mode: LaunchMode.externalApplication);
          },
        ),
        const SizedBox(height: 8),
        Text('A assinatura é feita na loja; depois é só voltar ao app.', style: AppTypography.caption, textAlign: TextAlign.center),
      ],
    );
  }
}
