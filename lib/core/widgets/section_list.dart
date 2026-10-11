import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'surface_card.dart';

/// Título de seção (14 bold) fora do card, com ícone dourado opcional e subtítulo.
class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, this.subtitle, this.icon, this.trailing});

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 20, color: AppColors.brandGold),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: AppTypography.bodyBold.copyWith(color: AppColors.textSecondary)),
                if (subtitle != null) Text(subtitle!, style: AppTypography.small.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Card branco com linhas separadas por divisor.
class SectionListCard extends StatelessWidget {
  const SectionListCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i < children.length - 1) rows.add(const Divider(height: 1));
    }
    return SurfaceCard(padding: EdgeInsets.zero, child: Column(children: rows));
  }
}

/// Linha: ícone dourado 20px, título bold 14, subtítulo 12 cinza, chevron.
class SectionRow extends StatelessWidget {
  const SectionRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.onTap,
    this.danger = false,
    this.disabled = false,
    this.trailing,
    this.badge,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool danger;

  /// Mostra a linha esmaecida (ação bloqueada), mantendo o toque para explicar.
  final bool disabled;
  final Widget? trailing;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final Color titleColor = danger ? AppColors.danger : (disabled ? AppColors.textMuted : AppColors.textPrimary);
    final Color iconColor = danger ? AppColors.danger : (disabled ? AppColors.textMuted : AppColors.brandGold);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDims.cardPadding, vertical: 14),
        child: Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(child: Text(title, style: AppTypography.bodyBold.copyWith(color: titleColor))),
                      if (badge != null) ...<Widget>[const SizedBox(width: 8), badge!],
                    ],
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(subtitle!, style: AppTypography.small.copyWith(color: AppColors.textMuted)),
                    ),
                ],
              ),
            ),
            trailing ??
                (onTap == null
                    ? const SizedBox.shrink()
                    : const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

/// Par rótulo/valor em uma linha (ex.: "Plano atual · Anual").
class KeyValueRow extends StatelessWidget {
  const KeyValueRow({super.key, required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: Text(label, style: AppTypography.small)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTypography.smallBold.copyWith(color: valueColor ?? AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
