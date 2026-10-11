import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/models/common.dart';
import '../../api/models/health.dart';
import '../../core/deep_links.dart';
import '../../core/formatting.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/prime_button.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/surface_card.dart';
import '../../data/providers.dart';
import '../../router.dart';
import 'health_controller.dart';

/// Resumo de saúde (GET /me/health/summary): últimos 7 dias, sugestões, sync
/// manual e desconectar. Sem consentimento mostra a chamada para conectar.
class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key});

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen> {
  bool _autoSynced = false;

  Future<void> _sync({bool force = true}) async {
    try {
      final HealthSummary? s = await ref.read(healthControllerProvider).sync(force: force);
      if (mounted && force) {
        showSuccessToast(context, s == null ? 'Nada novo para sincronizar' : 'Dados sincronizados');
      }
    } catch (e) {
      if (mounted) showErrorToast(context, e, title: 'Falha ao sincronizar');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool consent = ref.watch(consentGrantedProvider(ConsentKind.healthData));
    if (consent && !_autoSynced) {
      _autoSynced = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _sync(force: false));
    }
    final AsyncValue<HealthSummary> summary = ref.watch(healthSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Saúde e wearables')),
      body: !consent
          ? EmptyView(
              icon: Icons.favorite_outline_rounded,
              title: 'Conecte seu relógio ou app de exercício',
              body: 'Sugestões de rotina a partir dos seus passos, treinos e sono. Só com o seu consentimento.',
              action: PrimeButton(label: 'Conectar', expanded: false, onPressed: () async => context.push(Routes.healthConsent)),
            )
          : summary.when(
              loading: () => const LoadingView(),
              error: (Object e, _) => ErrorView(error: e, onRetry: () async => ref.invalidate(healthSummaryProvider)),
              data: (HealthSummary s) => RefreshIndicator(
                onRefresh: () => _sync(force: true),
                child: ListView(
                  padding: const EdgeInsets.all(AppDims.pageMargin),
                  children: <Widget>[
                    SurfaceCard(
                      child: Row(
                        children: <Widget>[
                          Icon(s.connected ? Icons.check_circle_rounded : Icons.sync_problem_rounded,
                              color: s.connected ? AppColors.success : AppColors.warningText),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(s.connected ? 'Conectado' : 'Aguardando primeira sincronização', style: AppTypography.bodyBold),
                                Text(
                                  Fmt.join(<String?>[
                                    s.provider == HealthProvider.appleHealth
                                        ? 'Apple Health'
                                        : s.provider == HealthProvider.healthConnect
                                            ? 'Health Connect'
                                            : null,
                                    if (s.lastSyncAt != null) 'última sync ${Fmt.dateTime(s.lastSyncAt)}',
                                  ]),
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                          ),
                          IconButton(tooltip: 'Sincronizar', icon: const Icon(Icons.sync_rounded), onPressed: () => _sync(force: true)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDims.sectionGap),
                    _WeekTable(days: s.last7Days),
                    if (s.suggestions.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppDims.sectionGap),
                      Text('Sugestões para sua rotina', style: AppTypography.h3),
                      const SizedBox(height: 8),
                      for (final HealthSuggestion sg in s.suggestions) ...<Widget>[
                        SurfaceCard(
                          onTap: sg.deepLink == null
                              ? null
                              : () {
                                  final String? route = DeepLinks.routeForString(sg.deepLink);
                                  if (route != null) context.push(route);
                                },
                          child: Row(
                            children: <Widget>[
                              const Icon(Icons.lightbulb_outline_rounded, color: AppColors.brandGold),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(sg.title, style: AppTypography.bodyBold),
                                    Text(sg.body, style: AppTypography.small),
                                  ],
                                ),
                              ),
                              if (sg.deepLink != null) const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                    const SizedBox(height: AppDims.sectionGap),
                    PrimeButton(
                      label: 'Desconectar e revogar consentimento',
                      variant: PrimeButtonVariant.danger,
                      onPressed: () async {
                        final bool? ok = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext ctx) => AlertDialog(
                            title: const Text('Desconectar saúde?'),
                            content: const Text('Paramos de ler e enviar seus dados. Para revogar a permissão do sistema, use os ajustes do aparelho.'),
                            actions: <Widget>[
                              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Manter')),
                              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Desconectar')),
                            ],
                          ),
                        );
                        if (ok != true) return;
                        try {
                          await ref.read(healthControllerProvider).disconnect();
                          if (context.mounted) showSuccessToast(context, 'Saúde desconectada');
                        } catch (e) {
                          if (context.mounted) showErrorToast(context, e);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enviamos apenas totais diários (passos, minutos ativos, treinos, sono) dos últimos 7 dias.',
                      style: AppTypography.caption,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _WeekTable extends StatelessWidget {
  const _WeekTable({required this.days});

  final List<HealthDay> days;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return SurfaceCard(child: Text('Sem dados nos últimos 7 dias ainda. Puxe para sincronizar.', style: AppTypography.small));
    }
    final List<HealthDay> sorted = List<HealthDay>.from(days)..sort((a, b) => a.date.compareTo(b.date));
    return SurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const SizedBox(width: 44),
              _h('Passos'),
              _h('Ativo'),
              _h('Treinos'),
              _h('Sono'),
            ],
          ),
          const Divider(),
          for (final HealthDay d in sorted)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 44,
                    child: Text(
                      DateTime.tryParse(d.date) == null ? d.date : '${Fmt.weekdayShort(DateTime.parse(d.date))}\n${Fmt.dayMonth(d.date)}',
                      style: AppTypography.caption,
                    ),
                  ),
                  _c(d.steps == null ? '—' : Fmt.integer(d.steps!)),
                  _c(d.activeMinutes == null ? '—' : '${d.activeMinutes} min'),
                  _c(d.workouts == null ? '—' : '${d.workouts}'),
                  _c(d.sleepMinutes == null ? '—' : '${(d.sleepMinutes! / 60).toStringAsFixed(1)} h'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _h(String t) => Expanded(child: Text(t, textAlign: TextAlign.center, style: AppTypography.caption));
  Widget _c(String t) => Expanded(child: Text(t, textAlign: TextAlign.center, style: AppTypography.smallBold));
}
