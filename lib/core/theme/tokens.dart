import 'package:flutter/material.dart';

/// Tokens de design derivados do Figma "Painel do assinante" (DESIGN.md).
/// Tema CLARO.
class AppColors {
  AppColors._();

  // Fundos
  static const Color bgPage = Color(0xFFF3F3F3);
  static const Color bgSurface = Color(0xFFFFFFFF);
  static const Color bgSubtle = Color(0xFFF8F9FA);
  static const Color bgMuted = Color(0xFFE9ECEF);
  static const Color border = Color(0xFFE9ECEF);
  static const Color borderStrong = Color(0xFFDEE2E6);

  // Marca
  static const Color brandDark = Color(0xFF260F0F);
  static const Color brandDark2 = Color(0xFF331E1E);
  static const Color brandPrimary = Color(0xFFF1D98A);
  static const Color brandPrimaryStrong = Color(0xFFEBC969);
  static const Color brandGold = Color(0xFFDBA73F);
  static const Color brandGoldDeep = Color(0xFFDDA41F);
  static const Color brandGradientStart = Color(0xFFC28B14);
  static const Color brandGradientEnd = Color(0xFFE4BD6F);
  static const Color brandPurple = Color(0xFF7B44DA);
  static const Color brandPurpleSoft = Color(0xFFEAE1F9);

  // Semânticas
  static const Color success = Color(0xFF82C91E);
  static const Color successDeep = Color(0xFF74B816);
  static const Color successSoft = Color(0xFFEEF6E2);
  static const Color successBadge = Color(0xFFC1DB96);
  static const Color successText = Color(0xFF2B8A3E);
  static const Color warning = Color(0xFFF59F00);
  static const Color warningSoft = Color(0xFFFFF3BF);
  static const Color warningText = Color(0xFFF08C00);
  static const Color danger = Color(0xFFC92A2A);
  static const Color dangerSoft = Color(0xFFFFE3E3);
  static const Color info = Color(0xFF006EBB);
  static const Color infoSoft = Color(0xFFD9F2FC);

  // Texto
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF495057);
  static const Color textMuted = Color(0xFF909296);
}

/// Forma e espaçamento.
class AppDims {
  AppDims._();

  static const double radiusCard = 12;
  static const double radiusButton = 8;
  static const double radiusBadge = 4;
  static const double iconCircle = 56;
  static const double buttonHeight = 44;
  static const double cardPadding = 16;
  static const double sectionGap = 12;
  static const double pageMargin = 16;

  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x0F000000), // ~6% de opacidade
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
}
