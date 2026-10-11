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
import '../../router.dart';
import 'reason_picker.dart';

/// Cancelamento: só quando `canCancel.allowed`. Mostra o que se perde, oferece
/// pausa como alternativa, pede motivo (GET /cancel-reasons) e confirma.
/// A taxa de cancelamento antecipado NÃO é calculada pelo app (§6.4).
class CancelScreen extends ConsumerStatefulWidget {
  const CancelScreen({super.key});

  @override
  ConsumerState<CancelScreen> createState() => _CancelScreenState();
}

class _CancelScreenState extends ConsumerState<CancelScreen> {
  ReasonOption? _reason;
  String? _followUp;
  bool _acknowledged = false;

  Future<void> _confirm() async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Cancelar a assinatura?'),
        content: const Text(
          'Você perde o desconto Prime, o frete grátis, os pontos do Caffeine Army X e os brindes. '
          'Esta ação não pode ser desfeita pelo app (mas você pode reativar depois).',
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Manter assinatura')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Cancelar assinatura', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(subscriptionActionsProvider).cancel(
            CancelRequest(reason: _reason?.code ?? 'other', answers: buildAnswers(_reason, _followUp)),
          );
      if (!mounted) return;
      showSuccessToast(context, 'Assinatura cancelada', body: 'Sentiremos sua falta. Você pode reativar quando quiser.');
      context.go(Routes.home);
    } catch (e) {
      if (mounted) showErrorToast(context, e, title: 'Não foi possível cancelar');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Dashboard> dashboard = ref.watch(dashboardProvider);
    final AsyncValue<List<ReasonOption>> reasons = ref.watch(cancelReasonsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Cancelar assinatura')),
      body: dashboard.when(
        loading: () => const LoadingView(),
        error: (Object e, _) => ErrorView(error: e, onRetry: () async => ref.invalidate(dashboardProvider)),
        data: (Dashboard d) {
          final Subscription? s = d.subscription;
          final Capability cap = d.capabilities.canCancel;
          if (s == null) return const EmptyView(title: 'Sem assinatura');
          if (!cap.allowed) {
            return ListView(
              padding: const EdgeInsets.all(AppDims.pageMargin),
              children: <Widget>[
                AlertCard(tone: AlertTone.warning, icon: Icons.lock_clock_rounded, title: 'Cancelamento indisponível', body: capabilityHint(cap)),
                if (cap.commitmentEndsAt != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    'Previsão de fim da fidelidade: ${Fmt.date(cap.commitmentEndsAt)} (estimativa, ciclo de 30 dias). '
                    'Depois do último pagamento da fidelidade, o cancelamento fica aberto até o dia anterior à cobrança seguinte.',
                    style: AppTypography.body,
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'Precisa cancelar antes? Fale com o atendimento: casos como gravidez, saúde ou mudança de país são avaliados individualmente.',
                  style: AppTypography.small,
                ),
                const SizedBox(height: 16),
                PrimeButton(label: 'Voltar', variant: PrimeButtonVariant.secondary, onPressed: () async => context.pop()),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppDims.pageMargin),
            children: <Widget>[
              AlertCard(
                tone: AlertTone.danger,
                icon: Icons.highlight_off_rounded,
                title: 'Você vai perder seus benefícios',
                body: 'Desconto de ${Fmt.percent(s.discount.temporaryPercentage ?? s.discount.percentage)} na caixa, frete grátis, '
                    'pontos no Caffeine Army X, brindes e sabores exclusivos.'
                    '${cap.closesAt != null ? ' Janela aberta até ${Fmt.date(cap.closesAt)}.' : ''}',
              ),
              const SizedBox(height: AppDims.sectionGap),
              if (d.capabilities.canPause.allowed)
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Que tal pausar em vez de cancelar?', style: AppTypography.h3),
                      const SizedBox(height: 4),
                      Text('Você mantém o desconto e volta quando quiser. Tem ${s.pauseCreditsLeft} crédito(s) de pausa.', style: AppTypography.small),
                      const SizedBox(height: 10),
                      PrimeButton(label: 'Pausar assinatura', onPressed: () async => context.push(Routes.pause)),
                    ],
                  ),
                ),
              if (d.capabilities.canPause.allowed) const SizedBox(height: AppDims.sectionGap),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Por que você está cancelando?', style: AppTypography.h3),
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
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _acknowledged,
                onChanged: (bool? v) => setState(() => _acknowledged = v ?? false),
                title: Text('Entendi que perco os benefícios e que a caixa já em preparo não é cancelada.', style: AppTypography.small),
              ),
              const SizedBox(height: 8),
              PrimeButton(
                label: 'Cancelar e perder benefícios',
                variant: PrimeButtonVariant.danger,
                onPressed: (!_acknowledged || (_reason == null && (reasons.valueOrNull?.isNotEmpty ?? false))) ? null : _confirm,
              ),
              const SizedBox(height: 8),
              Text(
                'Eventual taxa de cancelamento antecipado prevista nos Termos é avaliada pelo atendimento, não pelo app.',
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
