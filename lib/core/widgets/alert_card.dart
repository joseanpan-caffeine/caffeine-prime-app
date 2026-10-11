import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'surface_card.dart';

enum AlertTone { success, warning, danger, info, neutral }

/// Card de alerta: ícone à esquerda, título bold, texto, ações opcionais.
class AlertCard extends StatelessWidget {
  const AlertCard({
    super.key,
    required this.title,
    this.body,
    this.tone = AlertTone.info,
    this.icon,
    this.actions = const <Widget>[],
    this.onTap,
  });

  final String title;
  final String? body;
  final AlertTone tone;
  final IconData? icon;
  final List<Widget> actions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color accent;
    Color bg = AppColors.bgSurface;
    IconData defaultIcon;
    switch (tone) {
      case AlertTone.success:
        accent = AppColors.success;
        defaultIcon = Icons.check_circle_rounded;
        break;
      case AlertTone.warning:
        accent = AppColors.warningText;
        bg = AppColors.warningSoft;
        defaultIcon = Icons.pause_circle_filled_rounded;
        break;
      case AlertTone.danger:
        accent = AppColors.danger;
        bg = AppColors.dangerSoft;
        defaultIcon = Icons.error_rounded;
        break;
      case AlertTone.info:
        accent = AppColors.info;
        defaultIcon = Icons.info_rounded;
        break;
      case AlertTone.neutral:
        accent = AppColors.textSecondary;
        bg = AppColors.bgSubtle;
        defaultIcon = Icons.help_outline_rounded;
        break;
    }
    return SurfaceCard(
      color: bg,
      onTap: onTap,
      border: tone == AlertTone.danger ? Border.all(color: AppColors.danger.withAlpha(90)) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon ?? defaultIcon, color: accent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: AppTypography.bodyBold.copyWith(color: tone == AlertTone.danger ? accent : null)),
                    if (body != null && body!.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(body!, style: AppTypography.small),
                    ],
                  ],
                ),
              ),
              if (onTap != null) const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
          if (actions.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ],
      ),
    );
  }
}
