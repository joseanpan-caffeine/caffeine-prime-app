import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../api/models/capabilities.dart';
import '../../../api/models/common.dart';
import '../../../api/models/config.dart';
import '../../../api/models/dashboard.dart';
import '../../../api/models/subscription.dart';
import '../../../core/formatting.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/capability_gate.dart';
import '../../../core/widgets/section_list.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../router.dart';

/// Listas de seção da Home: Entrega e pagamento, Benefícios, Minha assinatura
/// (com "Meu plano" expansível e barra de vigência), Ajuda e cancelamento.
class HomeSections extends StatelessWidget {
  const HomeSections({super.key, required this.dashboard, required this.config});

  final Dashboard dashboard;
  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    final Subscription? s = dashboard.subscription;
    final Capabilities caps = dashboard.capabilities;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionTitle(title: 'Entrega e pagamento'),
        SectionListCard(
          children: <Widget>[
            SectionRow(
              icon: Icons.location_on_outlined,
              title: 'Endereço de entrega',
              subtitle: s?.shippingAddress == null ? 'Cadastre seu endereço' : s!.shippingAddress!.line1,
              disabled: s != null && !caps.canChangeAddress.allowed,
              onTap: () => guardCapability(context, caps.canChangeAddress, () => context.push(Routes.address),
                  title: 'Troca de endereço'),
            ),
            SectionRow(
              icon: Icons.credit_card_outlined,
              title: 'Forma de pagamento',
              subtitle: s?.paymentProfile == null
                  ? 'Nenhum cartão cadastrado'
                  : '${s!.paymentProfile!.brand} •••• ${s!.paymentProfile!.lastFour}',
              disabled: s != null && !caps.canChangeCard.allowed,
              onTap: () => guardCapability(context, caps.canChangeCard, () => context.push(Routes.cards),
                  title: 'Troca de cartão'),
            ),
            SectionRow(
              icon: Icons.receipt_long_outlined,
              title: 'Meus pedidos e faturas',
              subtitle: dashboard.latestBill == null
                  ? 'Histórico de caixas'
                  : 'Última: ciclo ${dashboard.latestBill!.cycle} · ${Fmt.money(dashboard.latestBill!.amount)}',
              onTap: () => context.push(Routes.orders),
            ),
          ],
        ),
        const SizedBox(height: AppDims.sectionGap),
        const SectionTitle(title: 'Benefícios exclusivos'),
        SectionListCard(
          children: <Widget>[
            SectionRow(
              icon: Icons.stars_rounded,
              title: 'Programa de pontos: Caffeine Army X',
              subtitle: '${Fmt.integer(dashboard.wallet.points)} ${dashboard.wallet.label} disponíveis',
              badge: const StatusBadge(label: 'EM BREVE', tone: BadgeTone.purple),
              onTap: () => _soon(context, 'Resgate de pontos'),
            ),
            SectionRow(
              icon: Icons.local_offer_outlined,
              title: 'Clube de Vantagens',
              subtitle: 'Descontos em parceiros',
              badge: const StatusBadge(label: 'EM BREVE', tone: BadgeTone.neutral),
              onTap: () => _soon(context, 'Clube de Vantagens'),
            ),
          ],
        ),
        const SizedBox(height: AppDims.sectionGap),
        const SectionTitle(title: 'Minha assinatura'),
        SectionListCard(
          children: <Widget>[
            if (s != null) _MyPlanRow(subscription: s, capabilities: caps),
            if (s != null && s.status == SubscriptionStatus.active)
              SectionRow(
                icon: Icons.pause_circle_outline_rounded,
                title: 'Pausar assinatura',
                subtitle: capabilityHint(caps.canPause).isEmpty
                    ? '${caps.canPause.creditsLeft ?? s.pauseCreditsLeft} crédito(s) de pausa'
                    : capabilityHint(caps.canPause),
                disabled: !caps.canPause.allowed,
                onTap: () => guardCapability(context, caps.canPause, () => context.push(Routes.pause), title: 'Pausa'),
              ),
            if (s != null && s.status == SubscriptionStatus.paused)
              SectionRow(
                icon: Icons.play_circle_outline_rounded,
                title: 'Retomar assinatura',
                subtitle: capabilityHint(caps.canResume),
                disabled: !caps.canResume.allowed,
                onTap: () => context.push(Routes.subscription),
              ),
            if (s != null && s.status == SubscriptionStatus.canceled)
              SectionRow(
                icon: Icons.replay_rounded,
                title: 'Reativar assinatura',
                subtitle: capabilityHint(caps.canReactivate),
                disabled: !caps.canReactivate.allowed,
                onTap: () => context.push(Routes.subscription),
              ),
            if (s == null)
              SectionRow(
                icon: Icons.add_circle_outline_rounded,
                title: 'Assinar o Prime',
                subtitle: 'Monte sua caixa com desconto e frete grátis',
                onTap: () => _open(config.links.subscribeUrl),
              ),
            SectionRow(
              icon: Icons.notifications_outlined,
              title: 'Notificações',
              subtitle: 'Cobrança, envio, renovação e rotina',
              onTap: () => context.push(Routes.notifications),
            ),
          ],
        ),
        const SizedBox(height: AppDims.sectionGap),
        const SectionTitle(title: 'Ajuda e suporte'),
        SectionListCard(
          children: <Widget>[
            SectionRow(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Fale conosco',
              subtitle: 'Atendimento Prime',
              onTap: () => _open(config.links.support),
            ),
            SectionRow(
              icon: Icons.description_outlined,
              title: 'Termos de assinatura',
              onTap: () => _open(config.links.terms),
            ),
            SectionRow(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacidade e consentimentos',
              onTap: () => context.push(Routes.consents),
            ),
            if (s != null && s.status != SubscriptionStatus.canceled)
              SectionRow(
                icon: Icons.highlight_off_rounded,
                title: 'Cancelar e perder benefícios',
                subtitle: caps.canCancel.allowed ? capabilityHint(caps.canCancel) : capabilityHint(caps.canCancel),
                danger: true,
                onTap: () => guardCapability(context, caps.canCancel, () => context.push(Routes.cancel),
                    title: 'Cancelamento'),
              ),
          ],
        ),
      ],
    );
  }

  static void _soon(BuildContext context, String name) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name: em breve no app.')));
  }

  static Future<void> _open(String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}

/// Linha "Meu plano" expansível: plano atual, assinante desde, vigência.
class _MyPlanRow extends StatefulWidget {
  const _MyPlanRow({required this.subscription, required this.capabilities});

  final Subscription subscription;
  final Capabilities capabilities;

  @override
  State<_MyPlanRow> createState() => _MyPlanRowState();
}

class _MyPlanRowState extends State<_MyPlanRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final Subscription s = widget.subscription;
    return Column(
      children: <Widget>[
        SectionRow(
          icon: Icons.workspace_premium_outlined,
          title: 'Meu plano',
          subtitle: '${s.planName.isNotEmpty ? s.planName : s.frequency.label} · próxima cobrança ${Fmt.date(s.nextBillingAt)}',
          onTap: () => setState(() => _open = !_open),
          trailing: Icon(_open ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: AppColors.textMuted),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.fromLTRB(48, 0, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                KeyValueRow(label: 'Plano atual', value: s.frequency.label),
                KeyValueRow(label: 'Assinante desde', value: Fmt.date(s.startedAt)),
                KeyValueRow(label: 'Ciclos pagos', value: '${s.paidCycles}'),
                KeyValueRow(label: 'Próxima cobrança', value: Fmt.date(s.nextBillingAt)),
                const SizedBox(height: 8),
                CommitmentBar(subscription: s, canCancel: widget.capabilities.canCancel),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push(Routes.plan),
                    child: const Text('Ver detalhes do plano'),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Barra "Vigência" dourada com "Restam X meses". Para Mensal (-1) não há fidelidade.
class CommitmentBar extends StatelessWidget {
  const CommitmentBar({super.key, required this.subscription, required this.canCancel});

  final Subscription subscription;
  final Capability canCancel;

  @override
  Widget build(BuildContext context) {
    final int remaining = subscription.remainingCommitmentMonths;
    if (remaining < 0) {
      return Text('Plano sem fidelidade.', style: AppTypography.small);
    }
    final int total = _commitmentMonths(subscription.frequency);
    final double progress = total <= 0 ? 1 : ((total - remaining) / total).clamp(0, 1).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text('Vigência', style: AppTypography.smallBold)),
            Text(
              remaining == 0 ? 'Fidelidade cumprida' : 'Restam $remaining ${remaining == 1 ? 'mês' : 'meses'}',
              style: AppTypography.small,
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.bgMuted,
            color: AppColors.warning,
          ),
        ),
        if (canCancel.commitmentEndsAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Previsão de término: ${Fmt.date(canCancel.commitmentEndsAt)} (estimativa, ciclo de 30 dias)',
              style: AppTypography.caption,
            ),
          ),
      ],
    );
  }

  /// Meses de fidelidade por plano, só para a proporção da barra (o valor
  /// exibido vem de `remainingCommitmentMonths`, da API).
  static int _commitmentMonths(Frequency f) {
    switch (f) {
      case Frequency.anual:
        return 12;
      case Frequency.semestral:
        return 6;
      case Frequency.trimestral:
        return 3;
      case Frequency.mensal:
      case Frequency.unknown:
        return 0;
    }
  }
}
