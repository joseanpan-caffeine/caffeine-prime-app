import 'package:flutter/material.dart';

import '../../api/models/common.dart';
import '../../api/models/subscription.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

enum BadgeTone { success, warning, danger, info, neutral, gold, purple, dark }

/// Badge/pill de status (radius 4 ou pill).
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, this.tone = BadgeTone.neutral, this.pill = true, this.icon});

  final String label;
  final BadgeTone tone;
  final bool pill;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (tone) {
      case BadgeTone.success:
        bg = AppColors.successSoft;
        fg = AppColors.successText;
        break;
      case BadgeTone.warning:
        bg = AppColors.warningSoft;
        fg = AppColors.warningText;
        break;
      case BadgeTone.danger:
        bg = AppColors.dangerSoft;
        fg = AppColors.danger;
        break;
      case BadgeTone.info:
        bg = AppColors.infoSoft;
        fg = AppColors.info;
        break;
      case BadgeTone.neutral:
        bg = AppColors.bgMuted;
        fg = AppColors.textSecondary;
        break;
      case BadgeTone.gold:
        bg = AppColors.brandGoldDeep;
        fg = AppColors.brandDark;
        break;
      case BadgeTone.purple:
        bg = AppColors.brandPurpleSoft;
        fg = AppColors.brandPurple;
        break;
      case BadgeTone.dark:
        bg = AppColors.brandDark;
        fg = AppColors.brandPrimary;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(pill ? 999 : AppDims.radiusBadge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[Icon(icon, size: 12, color: fg), const SizedBox(width: 4)],
          Text(label, style: AppTypography.badge.copyWith(color: fg)),
        ],
      ),
    );
  }
}

/// Badge de status da assinatura, com fallback para status desconhecido.
class SubscriptionStatusBadge extends StatelessWidget {
  const SubscriptionStatusBadge({super.key, required this.subscription, this.hasPendingBill = false});

  final Subscription? subscription;
  final bool hasPendingBill;

  @override
  Widget build(BuildContext context) {
    final Subscription? s = subscription;
    if (s == null) return const StatusBadge(label: 'SEM ASSINATURA', tone: BadgeTone.neutral);
    if (s.rawStatus != null && s.rawStatus!.isNotEmpty) {
      return StatusBadge(label: 'STATUS: ${s.rawStatus!.toUpperCase()}', tone: BadgeTone.neutral);
    }
    if (hasPendingBill && s.status == SubscriptionStatus.active) {
      return const StatusBadge(label: 'PAGAMENTO PENDENTE', tone: BadgeTone.danger);
    }
    switch (s.status) {
      case SubscriptionStatus.active:
        return const StatusBadge(label: 'ASSINATURA ATIVA', tone: BadgeTone.success);
      case SubscriptionStatus.future:
        return const StatusBadge(label: 'COMEÇA NA PRÓXIMA COBRANÇA', tone: BadgeTone.info);
      case SubscriptionStatus.paused:
        return const StatusBadge(label: 'ASSINATURA PAUSADA', tone: BadgeTone.warning);
      case SubscriptionStatus.canceled:
        return const StatusBadge(label: 'ASSINATURA CANCELADA', tone: BadgeTone.neutral);
      case SubscriptionStatus.fraudReview:
        return const StatusBadge(label: 'ASSINATURA EM ANÁLISE', tone: BadgeTone.info);
      case SubscriptionStatus.unknown:
        return const StatusBadge(label: 'STATUS DESCONHECIDO', tone: BadgeTone.neutral);
    }
  }
}

/// Badge "PRIME ANUAL" (bg #DDA41F, texto #260F0F).
class PlanBadge extends StatelessWidget {
  const PlanBadge({super.key, required this.frequency});

  final Frequency frequency;

  @override
  Widget build(BuildContext context) {
    return StatusBadge(label: 'PRIME ${frequency.label.toUpperCase()}', tone: BadgeTone.gold, pill: false);
  }
}
