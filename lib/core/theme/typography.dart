import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// Tipografia centralizada. A marca usa Acumin Pro (sem licença para embutir);
/// aqui usamos Archivo via google_fonts. Para trocar a fonte, mude só este arquivo.
///
/// Escala: display 28, h1 22, h2 18, h3 16, body 14, small 12, caption 11. Line-height 1.3.
class AppTypography {
  AppTypography._();

  static TextStyle _archivo({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double? letterSpacing,
  }) {
    return GoogleFonts.archivo(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.3,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle get display => _archivo(size: 28, weight: FontWeight.w700, letterSpacing: -0.3);
  static TextStyle get h1 => _archivo(size: 22, weight: FontWeight.w700, letterSpacing: -0.3);
  static TextStyle get h2 => _archivo(size: 18, weight: FontWeight.w700, letterSpacing: -0.3);
  static TextStyle get h3 => _archivo(size: 16, weight: FontWeight.w600);
  static TextStyle get body => _archivo(size: 14, color: AppColors.textSecondary);
  static TextStyle get bodyBold => _archivo(size: 14, weight: FontWeight.w600);
  static TextStyle get small => _archivo(size: 12, color: AppColors.textSecondary);
  static TextStyle get smallBold => _archivo(size: 12, weight: FontWeight.w600);
  static TextStyle get caption => _archivo(size: 11, color: AppColors.textMuted);
  static TextStyle get badge => _archivo(size: 10, weight: FontWeight.w700, letterSpacing: 0.4);

  /// TextTheme do Material 3 com Archivo.
  static TextTheme textTheme(TextTheme base) {
    final TextTheme archivo = GoogleFonts.archivoTextTheme(base);
    return archivo.copyWith(
      displaySmall: display,
      headlineMedium: h1,
      headlineSmall: h2,
      titleMedium: h3,
      titleSmall: bodyBold,
      bodyMedium: body,
      bodySmall: small,
      labelSmall: caption,
      labelLarge: _archivo(size: 14, weight: FontWeight.w600),
    );
  }
}
