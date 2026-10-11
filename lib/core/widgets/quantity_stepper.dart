import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';

/// Stepper de quantidade: caixa cinza com − e + nas pontas.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
    this.enabled = true,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final bool canDec = enabled && value > min;
    final bool canInc = enabled && value < max;
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.bgSubtle,
        borderRadius: BorderRadius.circular(AppDims.radiusButton),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _StepButton(icon: Icons.remove, onTap: canDec ? () => onChanged(value - 1) : null),
          SizedBox(
            width: 32,
            child: Text('$value', textAlign: TextAlign.center, style: AppTypography.bodyBold),
          ),
          _StepButton(icon: Icons.add, onTap: canInc ? () => onChanged(value + 1) : null),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDims.radiusButton),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(icon, size: 18, color: onTap == null ? AppColors.textMuted : AppColors.textPrimary),
      ),
    );
  }
}
