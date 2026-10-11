import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/models/capabilities.dart';
import '../../api/models/dashboard.dart';
import '../../api/models/editing.dart';
import '../../api/models/subscription.dart';
import '../../core/formatting.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/alert_card.dart';
import '../../core/widgets/capability_gate.dart';
import '../../core/widgets/prime_button.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/surface_card.dart';
import '../../data/providers.dart';
import '../../data/subscription_actions.dart';
import 'reason_picker.dart';

/// Pausar assinatura: escolhe ciclos (1..maxCycles, limitado aos créditos),
/// motivo (GET /pause-reasons) e confirma. Regras vêm de `canPause`.
class PauseScreen extends ConsumerStatefulWidget {
  const PauseScreen({super.key});

  @override
  ConsumerState<PauseScreen> createState() => _PauseScreenState();
}

class _PauseScreenState extends ConsumerState<PauseScreen> {
  int _cycles = 1;
  ReasonOption? _reason;
  String? _followUp;

  Future<void> _confirm(Subscription s) async {
    final String reason = _reason?.code ?? 'other';
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text('Pausar por $_cycles ${_cycles == 1 ? 'ciclo' : 'ciclos'}?'),
        content: Text(
          'Você não recebe caixa nem é cobrado nesses ciclos (a fatura vem em R\$ 0,00). '
          'Cada ciclo pausado usa 1 crédito e não conta para a fidelidade. '
          'A próxima cobrança seria em ${Fmt.date(s.nextBillingAt)}.',
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Voltar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Pausar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(subscriptionActionsProvider).pause(
            PauseRequest(cycles: _cycles, reason: reason, answers: buildAnswers(_reason, _followUp)),
          );
      if (!mounted) return;
      showSuccessToast(context, 'Assinatura pausada', body: 'Você pode desfazer até 5 dias antes da cobrança pausada.');
      context.pop();
    } catch (e) {
      if (mounted) showErrorToast(context, e, title: 'Não foi possível pausar');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Dashboard> dashboard = ref.watch(dashboardProvider);
    final AsyncValue<List<ReasonOption>> reasons = ref.watch(pauseReasonsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Pausar assinatura')),
      body: dashboard.when(
        loading: () => const LoadingView(),
        error: (Object e, _) => ErrorView(error: e, onRetry: () async => ref.invalidate(dashboardProvider)),
        data: (Dashboard d) {
          final Subscription? s = d.subscription;
          final Capability cap = d.capabilities.canPause;
          if (s == null) return const EmptyView(title: 'Sem assinatura');
          if (!cap.allowed) {
            return ListView(
              padding: const EdgeInsets.all(AppDims.pageMargin),
              children: <Widget>[
                AlertCard(tone: AlertTone.warning, title: 'Pausa indisponível', body: capabilityHint(cap)),
                const SizedBox(height: 16),
                PrimeButton(label: 'Voltar', variant: PrimeButtonVariant.secondary, onPressed: () async => context.pop()),
              ],
            );
          }
          final int credits = cap.creditsLeft ?? s.pauseCreditsLeft;
          final int max = (cap.maxCycles ?? 2).clamp(1, credits > 0 ? credits : 1).toInt();
          if (_cycles > max) _cycles = max;
          return ListView(
            padding: const EdgeInsets.all(AppDims.pageMargin),
            children: <Widget>[
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Quantos ciclos?', style: AppTypography.h3),
                    const SizedBox(height: 4),
                    Text('Você tem $credits crédito(s). Cada ciclo pausado pula exatamente uma cobrança.', style: AppTypography.small),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        for (int c = 1; c <= max; c++) ...<Widget>[
                          ChoiceChip(
                            label: Text('$c ${c == 1 ? 'ciclo' : 'ciclos'}'),
                            selected: _cycles == c,
                            onSelected: (_) => setState(() => _cycles = c),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                    if (cap.closesAt != null) ...<Widget>[
                      const SizedBox(height: 10),
                      Text('Pedido de pausa disponível até ${Fmt.dateTime(cap.closesAt)}.', style: AppTypography.caption),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppDims.sectionGap),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Por que você quer pausar?', style: AppTypography.h3),
                    const SizedBox(height: 4),
                    reasons.when(
                      loading: () => const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
                      error: (_, __) => Text('Motivos indisponíveis no momento.', style: AppTypography.small),
                      data: (List<ReasonOption> list) => ReasonPicker(
                        options: list,
                        selected: _reason,
                        followUpAnswer: _followUp,
                        onSelected: (ReasonOption r) => setState(() {
                          _reason = r;
                          _followUp = null;
                        }),
                        onFollowUp: (String a) => setState(() => _followUp = a),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDims.sectionGap),
              const AlertCard(
                tone: AlertTone.neutral,
                title: 'Dica: lata acumulando?',
                body: 'Em vez de pausar, você pode reduzir a quantidade ou trocar um item para recorrência de 60 dias no editor da caixa.',
              ),
              const SizedBox(height: 20),
              PrimeButton(
                label: 'Confirmar pausa',
                onPressed: (_reason == null && (reasons.valueOrNull?.isNotEmpty ?? false)) ? null : () => _confirm(s),
              ),
              const SizedBox(height: 8),
              Text(
                'Enquanto pausada, a Vindi continua gerando uma fatura por ciclo com valor R\$ 0,00. É esperado.',
                style: AppTypography.caption,
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }
}
