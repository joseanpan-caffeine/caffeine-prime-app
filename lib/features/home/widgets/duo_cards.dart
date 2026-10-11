import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../api/models/dashboard.dart';
import '../../../core/formatting.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/surface_card.dart';

/// Dupla de cards: Caffeine Army X (roxo) e Clube de Vantagens (dourado).
/// Pontos vêm de `wallet`; o Clube ainda não tem dado na API (texto genérico).
class DuoCards extends StatelessWidget {
  const DuoCards({super.key, required this.dashboard, this.onCaffeineX, this.onClube});

  final Dashboard dashboard;
  final VoidCallback? onCaffeineX;
  final VoidCallback? onClube;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: SurfaceCard(
            color: AppColors.brandPurpleSoft,
            onTap: onCaffeineX,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SvgPicture.asset('assets/brand/caffeine-x.svg', width: 28, height: 28),
                const SizedBox(height: 8),
                Text('Caffeine Army X', style: AppTypography.smallBold),
                Text(
                  'Você possui ${Fmt.integer(dashboard.wallet.points)} ${dashboard.wallet.label}',
                  style: AppTypography.small.copyWith(color: AppColors.brandPurple, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SurfaceCard(
            onTap: onClube,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.local_offer_rounded, color: AppColors.brandGold, size: 28),
                const SizedBox(height: 8),
                Text('Clube de Vantagens', style: AppTypography.smallBold),
                Text('Descontos em parceiros', style: AppTypography.small.copyWith(color: AppColors.brandGold, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
