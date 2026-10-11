import 'package:flutter/material.dart';

import 'tokens.dart';
import 'typography.dart';

/// Tema claro do app, Material 3 com ColorScheme custom a partir dos tokens.
class AppTheme {
  AppTheme._();

  static const ColorScheme colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.brandPrimary,
    onPrimary: AppColors.brandDark,
    primaryContainer: AppColors.brandPrimaryStrong,
    onPrimaryContainer: AppColors.brandDark,
    secondary: AppColors.brandGold,
    onSecondary: AppColors.brandDark,
    secondaryContainer: AppColors.bgSubtle,
    onSecondaryContainer: AppColors.textPrimary,
    tertiary: AppColors.brandPurple,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.brandPurpleSoft,
    onTertiaryContainer: AppColors.brandPurple,
    error: AppColors.danger,
    onError: Colors.white,
    errorContainer: AppColors.dangerSoft,
    onErrorContainer: AppColors.danger,
    surface: AppColors.bgSurface,
    onSurface: AppColors.textPrimary,
    surfaceContainerHighest: AppColors.bgMuted,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.borderStrong,
    outlineVariant: AppColors.border,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.brandDark,
    onInverseSurface: Colors.white,
    inversePrimary: AppColors.brandGold,
  );

  static ThemeData light() {
    final ThemeData base = ThemeData(useMaterial3: true, colorScheme: colorScheme);
    final TextTheme textTheme = AppTypography.textTheme(base.textTheme);
    const RoundedRectangleBorder buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppDims.radiusButton)),
    );
    const Size buttonSize = Size(64, AppDims.buttonHeight);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bgPage,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgSurface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: AppTypography.h3,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      // cardTheme não é definido de propósito: o tipo mudou entre versões do Flutter
      // (CardTheme → CardThemeData). Cards usam o widget próprio SurfaceCard.
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: AppColors.brandDark,
          disabledBackgroundColor: AppColors.bgMuted,
          disabledForegroundColor: AppColors.textMuted,
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: AppTypography.bodyBold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: AppColors.brandDark,
          disabledBackgroundColor: AppColors.bgMuted,
          elevation: 0,
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: AppTypography.bodyBold,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.bgSurface,
          foregroundColor: AppColors.brandDark,
          side: const BorderSide(color: AppColors.brandPrimary, width: 1.5),
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: AppTypography.bodyBold,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandDark,
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: AppTypography.bodyBold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDims.radiusButton),
          borderSide: const BorderSide(color: AppColors.borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDims.radiusButton),
          borderSide: const BorderSide(color: AppColors.borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDims.radiusButton),
          borderSide: const BorderSide(color: AppColors.brandGold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDims.radiusButton),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        labelStyle: AppTypography.body,
        hintStyle: AppTypography.body.copyWith(color: AppColors.textMuted),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.bgSurface,
        indicatorColor: AppColors.brandPrimary,
        labelTextStyle: WidgetStateProperty.all(AppTypography.caption.copyWith(color: AppColors.textSecondary)),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final bool selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? AppColors.brandDark : AppColors.textMuted, size: 22);
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTypography.body.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDims.radiusButton)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bgSubtle,
        selectedColor: AppColors.brandPrimary,
        labelStyle: AppTypography.small.copyWith(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.brandDark : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.brandPrimary : AppColors.bgMuted,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.brandGold),
    );
  }
}
