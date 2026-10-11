import 'package:flutter/material.dart';

import '../../api/models/capabilities.dart';
import '../formatting.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'prime_button.dart';

/// Texto curto para mostrar ao lado de uma ação sujeita a `capabilities`.
/// Permitida com janela → "até 14/07"; bloqueada → razão (+ "reabre em …").
String capabilityHint(Capability cap) {
  if (cap.allowed) {
    if (cap.closesAt != null) return 'Disponível até ${Fmt.date(cap.closesAt)}';
    return '';
  }
  final String reason = capabilityReasonLabel(cap.reason);
  if (cap.until != null) return '$reason Reabre em ${Fmt.date(cap.until)}.';
  return reason;
}

/// Executa [action] se a capability permitir; senão explica o motivo em um
/// bottom sheet. O app nunca calcula prazo: usa `until`/`closesAt` do servidor.
void guardCapability(BuildContext context, Capability cap, VoidCallback action, {String? title}) {
  if (cap.allowed) {
    action();
    return;
  }
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.lock_clock_rounded, color: AppColors.warningText),
                  const SizedBox(width: 8),
                  Expanded(child: Text(title ?? 'Ação indisponível agora', style: AppTypography.h3)),
                ],
              ),
              const SizedBox(height: 12),
              Text(capabilityReasonLabel(cap.reason), style: AppTypography.body),
              if (cap.until != null) ...<Widget>[
                const SizedBox(height: 8),
                Text('Volta a ficar disponível em ${Fmt.dateTime(cap.until)}.', style: AppTypography.bodyBold),
              ],
              if (cap.commitmentEndsAt != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  'Previsão de fim da fidelidade: ${Fmt.date(cap.commitmentEndsAt)} '
                  '(estimativa: o ciclo é de 30 dias, não um dia fixo do mês).',
                  style: AppTypography.small,
                ),
              ],
              const SizedBox(height: 20),
              PrimeButton(label: 'Entendi', variant: PrimeButtonVariant.secondary, onPressed: () async => Navigator.of(ctx).pop()),
            ],
          ),
        ),
      );
    },
  );
}
