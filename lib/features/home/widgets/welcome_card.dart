import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../api/models/dashboard.dart';
import '../../../api/models/subscription.dart';
import '../../../core/formatting.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/capability_gate.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../router.dart';

/// Card de boas-vindas: badge do plano, "Olá, {nome}", status, ações rápidas
/// e faixa de economia.
class WelcomeCard extends StatelessWidget {
  const WelcomeCard({super.key, required this.dashboard, required this.onLogout, this.onAssistant});

  final Dashboard dashboard;
  final VoidCallback onLogout;
  final VoidCallback? onAssistant;

  @override
  Widget build(BuildContext context) {
    final Subscription? s = dashboard.subscription;
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (s != null) PlanBadge(frequency: s.frequency),
                      const SizedBox(height: 6),
                      Text(
                        'Olá, ${dashboard.user.firstName}',
                        style: AppTypography.h1.copyWith(color: AppColors.brandGold, fontSize: 20),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    SubscriptionStatusBadge(subscription: s, hasPendingBill: dashboard.capabilities.hasPendingBill),
                    IconButton(
                      tooltip: 'Sair',
                      icon: const Icon(Icons.logout_rounded, size: 20, color: AppColors.textMuted),
                      onPressed: onLogout,
                    ),
                  ],
                ),
              ],
            ),
          ),
          _QuickActions(dashboard: dashboard, onAssistant: onAssistant),
          const SizedBox(height: 12),
          _SavingsStrip(dashboard: dashboard),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.dashboard, this.onAssistant});

  final Dashboard dashboard;
  final VoidCallback? onAssistant;

  @override
  Widget build(BuildContext context) {
    final bool hasSub = dashboard.subscription != null;
    final List<_QuickAction> actions = <_QuickAction>[
      _QuickAction(
        icon: Icons.inventory_2_outlined,
        label: 'Editar\nCaixa',
        enabled: hasSub,
        onTap: () => guardCapability(context, dashboard.capabilities.canEdit, () => context.push(Routes.box),
            title: 'Edição da caixa'),
      ),
      _QuickAction(icon: Icons.receipt_long_outlined, label: 'Perfil e\nPedidos', onTap: () => context.push(Routes.orders)),
      _QuickAction(
        icon: Icons.card_membership_outlined,
        label: 'Minha\nAssinatura',
        onTap: () => context.push(hasSub ? Routes.plan : Routes.subscription),
      ),
      _QuickAction(
        icon: Icons.stars_outlined,
        label: 'Caffeine\nArmy X',
        color: AppColors.brandPurple,
        onTap: () => _comingSoon(context, 'Caffeine Army X'),
      ),
      if (onAssistant != null)
        _QuickAction(icon: Icons.auto_awesome_outlined, label: 'Prime\nIA', onTap: onAssistant!)
      else
        _QuickAction(
          icon: Icons.local_offer_outlined,
          label: 'Clube de\nVantagens',
          onTap: () => _comingSoon(context, 'Clube de Vantagens'),
        ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: actions.map((a) => Expanded(child: a)).toList(),
      ),
    );
  }

  static void _comingSoon(BuildContext context, String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name: em breve no app. Por enquanto, acesse pela Área do Assinante na web.')),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap, this.enabled = true, this.color});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Column(
          children: <Widget>[
            Container(
              width: AppDims.iconCircle,
              height: AppDims.iconCircle,
              decoration: const BoxDecoration(color: AppColors.bgSubtle, shape: BoxShape.circle),
              child: Icon(icon, color: enabled ? (color ?? AppColors.textSecondary) : AppColors.textMuted, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: AppTypography.caption.copyWith(color: enabled ? AppColors.textSecondary : AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Faixa de economia: total + últimos 12 meses (valores da API, sem recalcular).
class _SavingsStrip extends StatelessWidget {
  const _SavingsStrip({required this.dashboard});

  final Dashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final Savings sv = dashboard.savings;
    return Container(
      color: AppColors.bgSubtle,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Economia total', style: AppTypography.small),
                Text(Fmt.money(sv.sinceStart), style: AppTypography.h1.copyWith(color: AppColors.brandGold)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text('Últimos 12 meses', style: AppTypography.small),
              Text(Fmt.money(sv.last12Months), style: AppTypography.bodyBold),
              const SizedBox(height: 4),
              Text(
                '${Fmt.integer(dashboard.wallet.points)} ${dashboard.wallet.label}',
                style: AppTypography.smallBold.copyWith(color: AppColors.brandPurple),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
