import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';

enum PrimeButtonVariant { primary, secondary, ghost, danger, success, purple, dark }

/// Botão do design system (altura 44, radius 8) com proteção contra toque
/// duplo: enquanto `onPressed` (async) roda, mostra spinner e ignora toques.
class PrimeButton extends StatefulWidget {
  const PrimeButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = PrimeButtonVariant.primary,
    this.icon,
    this.expanded = true,
    this.loading = false,
    this.small = false,
  });

  final String label;

  /// Pode ser síncrono ou devolver um Future; o botão trava até terminar.
  final Future<void> Function()? onPressed;
  final PrimeButtonVariant variant;
  final IconData? icon;
  final bool expanded;

  /// Força o estado de carregando (controlado de fora).
  final bool loading;
  final bool small;

  @override
  State<PrimeButton> createState() => _PrimeButtonState();
}

class _PrimeButtonState extends State<PrimeButton> {
  bool _busy = false;

  Future<void> _handle() async {
    if (_busy || widget.onPressed == null) return;
    setState(() => _busy = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool loading = _busy || widget.loading;
    final bool enabled = widget.onPressed != null && !loading;

    Color bg;
    Color fg;
    BorderSide? side;
    switch (widget.variant) {
      case PrimeButtonVariant.primary:
        bg = AppColors.brandPrimary;
        fg = AppColors.brandDark;
        break;
      case PrimeButtonVariant.secondary:
        bg = AppColors.bgSurface;
        fg = AppColors.brandDark;
        side = const BorderSide(color: AppColors.brandPrimary, width: 1.5);
        break;
      case PrimeButtonVariant.ghost:
        bg = Colors.transparent;
        fg = AppColors.brandDark;
        break;
      case PrimeButtonVariant.danger:
        bg = Colors.transparent;
        fg = AppColors.danger;
        break;
      case PrimeButtonVariant.success:
        bg = AppColors.success;
        fg = Colors.white;
        break;
      case PrimeButtonVariant.purple:
        bg = AppColors.brandPurple;
        fg = Colors.white;
        break;
      case PrimeButtonVariant.dark:
        bg = AppColors.brandDark;
        fg = Colors.white;
        break;
    }
    if (!enabled && !loading) {
      bg = widget.variant == PrimeButtonVariant.ghost || widget.variant == PrimeButtonVariant.danger
          ? Colors.transparent
          : AppColors.bgMuted;
      fg = AppColors.textMuted;
      side = null;
    }

    final double height = widget.small ? 36 : AppDims.buttonHeight;
    final Widget child = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (widget.icon != null) ...<Widget>[
                Icon(widget.icon, size: 18, color: fg),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: (widget.small ? AppTypography.smallBold : AppTypography.bodyBold).copyWith(color: fg),
                ),
              ),
            ],
          );

    final ButtonStyle style = ButtonStyle(
      backgroundColor: WidgetStatePropertyAll<Color>(bg),
      foregroundColor: WidgetStatePropertyAll<Color>(fg),
      overlayColor: WidgetStatePropertyAll<Color>(fg.withAlpha(20)),
      elevation: const WidgetStatePropertyAll<double>(0),
      minimumSize: WidgetStatePropertyAll<Size>(Size(widget.small ? 48 : 64, height)),
      padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(horizontal: widget.small ? 12 : 16),
      ),
      shape: WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDims.radiusButton),
          side: side ?? BorderSide.none,
        ),
      ),
    );

    final Widget button = TextButton(
      onPressed: enabled ? _handle : null,
      style: style,
      child: child,
    );
    if (!widget.expanded) return button;
    return SizedBox(width: double.infinity, height: height, child: button);
  }
}
