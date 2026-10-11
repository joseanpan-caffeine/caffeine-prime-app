import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Card branco com radius 12 e sombra suave (DESIGN.md "Forma").
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDims.cardPadding),
    this.color = AppColors.bgSurface,
    this.onTap,
    this.border,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final VoidCallback? onTap;
  final BoxBorder? border;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final Widget content = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppDims.radiusCard),
        boxShadow: AppDims.cardShadow,
        border: border,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDims.radiusCard),
        child: Padding(padding: padding, child: child),
      ),
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDims.radiusCard),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

/// Card escuro `#260F0F` ("próxima caixa", header do perfil).
class DarkCard extends StatelessWidget {
  const DarkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDims.cardPadding),
    this.muted = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Variante clara/desaturada (pagamento pendente).
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: muted ? AppColors.bgSubtle : AppColors.brandDark,
        borderRadius: BorderRadius.circular(AppDims.radiusCard),
        boxShadow: AppDims.cardShadow,
        border: muted ? Border.all(color: AppColors.borderStrong) : null,
      ),
      padding: padding,
      child: child,
    );
  }
}
