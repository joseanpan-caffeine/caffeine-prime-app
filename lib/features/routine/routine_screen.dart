import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/models/common.dart';
import '../../api/models/routine.dart';
import '../../core/analytics.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/streak.dart';
import '../../core/widgets/prime_button.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/surface_card.dart';
import '../../data/providers.dart';
import '../../router.dart';
import 'routine_controller.dart';
import 'widgets/routine_widgets.dart';

/// Aba Rotina (frente 2): check-ins de hoje, sequência/meta, heatmap,
/// lembretes por item, dicas de uso e previsão de estoque. Na primeira
/// abertura pede o consentimento `routine_data`.
class RoutineScreen extends ConsumerStatefulWidget {
  const RoutineScreen({super.key});

  @override
  ConsumerState<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends ConsumerState<RoutineScreen> {
  final Set<String> _busy = <String>{};
  bool _sheetShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(analyticsProvider).screen('routine'));
  }

  Future<void> _toggle(RoutineItem item, bool done) async {
    if (_busy.contains(item.id)) return;
    setState(() => _busy.add(item.id));
    try {
      if (done) {
        await ref.read(routineControllerProvider).undo(item.id);
      } else {
        await ref.read(routineControllerProvider).checkIn(item.id);
      }
    } catch (e) {
      if (mounted) showErrorToast(context, e);
    } finally {
      if (mounted) setState(() => _busy.remove(item.id));
    }
  }

  Future<void> _editReminder(RoutineItem item) async {
    final ({int hour, int minute}) t = StreakHelper.parseHhMm(item.reminderTime ?? item.slot.defaultTime) ?? (hour: 8, minute: 0);
    bool enabled = item.reminderEnabled;
    TimeOfDay time = TimeOfDay(hour: t.hour, minute: t.minute);
    RoutineSlot slot = item.slot;
    final bool? save = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, void Function(void Function()) setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.title, style: AppTypography.h3),
                if (item.usageHint != null) Text(item.usageHint!, style: AppTypography.small),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Lembrete diário'),
                  value: enabled,
                  onChanged: (bool v) => setSheet(() => enabled = v),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule_rounded, color: AppColors.brandGold),
                  title: const Text('Horário'),
                  trailing: Text(time.format(ctx), style: AppTypography.bodyBold),
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(context: ctx, initialTime: time);
                    if (picked != null) setSheet(() => time = picked);
                  },
                ),
                const SizedBox(height: 4),
                Text('Momento do dia', style: AppTypography.smallBold),
                Wrap(
                  spacing: 8,
                  children: RoutineSlot.values
                      .where((s) => s != RoutineSlot.unknown)
                      .map((s) => ChoiceChip(label: Text(s.label), selected: slot == s, onSelected: (_) => setSheet(() => slot = s)))
                      .toList(),
                ),
                const SizedBox(height: 16),
                PrimeButton(label: 'Salvar', onPressed: () async => Navigator.of(ctx).pop(true)),
              ],
            ),
          ),
        ),
      ),
    );
    if (save != true) return;
    try {
      await ref.read(routineControllerProvider).updateItem(
            item.copyWith(
              reminderEnabled: enabled,
              reminderTime: '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              slot: slot,
            ),
          );
      if (mounted) showSuccessToast(context, enabled ? 'Lembrete salvo' : 'Lembrete desativado');
    } catch (e) {
      if (mounted) showErrorToast(context, e);
    }
  }

  Future<void> _editGoal(int current) async {
    int goal = current;
    final bool? ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, void Function(void Function()) setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Meta semanal', style: AppTypography.h3),
                Text('Em quantos dias da semana você quer completar a rotina?', style: AppTypography.small),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: List<Widget>.generate(7, (int i) {
                    final int d = i + 1;
                    return ChoiceChip(label: Text('$d'), selected: goal == d, onSelected: (_) => setSheet(() => goal = d));
                  }),
                ),
                const SizedBox(height: 16),
                PrimeButton(label: 'Salvar meta', onPressed: () async => Navigator.of(ctx).pop(true)),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(routineControllerProvider).setWeeklyGoal(goal);
    } catch (e) {
      if (mounted) showErrorToast(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool consent = ref.watch(consentGrantedProvider(ConsentKind.routineData));
    final AsyncValue<dynamic> consentsLoad = ref.watch(consentsProvider);
    final bool assistantOn = ref.watch(appConfigValueProvider).feature('assistant');

    if (!consent) {
      if (consentsLoad.isLoading) {
        return Scaffold(appBar: AppBar(title: const Text('Rotina')), body: const LoadingView());
      }
      return Scaffold(
        appBar: AppBar(title: const Text('Rotina')),
        body: _OnboardingView(
          onEnable: (bool reminders) async {
            try {
              await ref.read(routineControllerProvider).enable(withReminders: reminders);
              if (mounted) showSuccessToast(context, 'Rotina ativada!', body: 'Marque seus check-ins todo dia.');
            } catch (e) {
              if (mounted) showErrorToast(context, e);
            }
          },
          autoOpenSheet: !_sheetShown,
          onSheetShown: () => _sheetShown = true,
        ),
      );
    }

    final AsyncValue<RoutinePlan> plan = ref.watch(routinePlanProvider);
    final AsyncValue<RoutineSummary> summary = ref.watch(routineSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rotina'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Saúde e wearables',
            icon: const Icon(Icons.favorite_outline_rounded),
            onPressed: () => context.push(Routes.health),
          ),
        ],
      ),
      floatingActionButton: assistantOn
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.brandDark,
              foregroundColor: AppColors.brandPrimary,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Prime IA'),
              onPressed: () => context.go(Routes.assistant),
            )
          : null,
      body: plan.when(
        loading: () => const LoadingView(),
        error: (Object e, _) => ErrorView(error: e, onRetry: () async => ref.invalidate(routinePlanProvider)),
        data: (RoutinePlan p) {
          final RoutineSummary? s = summary.valueOrNull;
          final List<StockForecast>? forecast = s?.stockForecast;
          String titleFor(String handle) {
            for (final RoutineItem i in p.items) {
              if (i.productHandle == handle) return i.title;
            }
            return handle;
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(routinePlanProvider);
              ref.invalidate(routineSummaryProvider);
              await ref.read(routineSummaryProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppDims.pageMargin, AppDims.pageMargin, AppDims.pageMargin, 96),
              children: <Widget>[
                if (s != null)
                  StreakCard(summary: s, weeklyGoalDays: p.weeklyGoalDays, onGoalTap: () => _editGoal(p.weeklyGoalDays))
                else if (summary.hasError)
                  ErrorView(error: summary.error!, compact: true, onRetry: () async => ref.invalidate(routineSummaryProvider))
                else
                  const SizedBox(height: 120, child: LoadingView()),
                const SizedBox(height: AppDims.sectionGap),
                Text('Hoje', style: AppTypography.h3),
                const SizedBox(height: 8),
                if (p.items.isEmpty)
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Nenhum item na rotina', style: AppTypography.bodyBold),
                        Text('Sua rotina é montada a partir da caixa. Edite a caixa e volte aqui.', style: AppTypography.small),
                        const SizedBox(height: 8),
                        PrimeButton(label: 'Editar caixa', expanded: false, onPressed: () async => context.push(Routes.box)),
                      ],
                    ),
                  ),
                for (final RoutineItem item in p.items) ...<Widget>[
                  CheckInRow(
                    item: item,
                    done: s?.today.isDone(item.id) ?? false,
                    busy: _busy.contains(item.id),
                    onToggle: () => _toggle(item, s?.today.isDone(item.id) ?? false),
                    onReminder: () => _editReminder(item),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 4),
                if (s != null) Heatmap28(days: s.last28Days),
                if (forecast != null && forecast.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppDims.sectionGap),
                  StockForecastCard(forecast: forecast, titleFor: titleFor),
                ],
                const SizedBox(height: AppDims.sectionGap),
                Text(
                  'Lembretes são notificações locais deste aparelho, no fuso ${p.timezone}. Seus check-ins ficam na sua conta.',
                  style: AppTypography.caption,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Onboarding: explica e pede o consentimento `routine_data` (PUT /me/consents).
class _OnboardingView extends StatefulWidget {
  const _OnboardingView({required this.onEnable, required this.autoOpenSheet, required this.onSheetShown});

  final Future<void> Function(bool reminders) onEnable;
  final bool autoOpenSheet;
  final VoidCallback onSheetShown;

  @override
  State<_OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<_OnboardingView> {
  bool _reminders = true;

  @override
  void initState() {
    super.initState();
    if (widget.autoOpenSheet) {
      widget.onSheetShown();
      WidgetsBinding.instance.addPostFrameCallback((_) => _openSheet());
    }
  }

  Future<void> _openSheet() async {
    if (!mounted) return;
    bool reminders = _reminders;
    final bool? ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, void Function(void Function()) setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.check_circle_outline_rounded, color: AppColors.brandGold, size: 36),
                const SizedBox(height: 8),
                Text('Ative sua rotina Prime', style: AppTypography.h2),
                const SizedBox(height: 8),
                Text(
                  'Marque todo dia o que você tomou, acompanhe sua sequência e receba lembretes nos horários certos. '
                  'Assim a lata não acumula e você aproveita cada produto.',
                  style: AppTypography.body,
                ),
                const SizedBox(height: 12),
                Text('O que guardamos (consentimento "Dados de rotina e hábitos")', style: AppTypography.smallBold),
                const SizedBox(height: 4),
                Text(
                  '• Seus check-ins (item, dia e hora)\n'
                  '• Horários de lembrete e meta semanal\n'
                  '• Nada é compartilhado com terceiros; você pode revogar em Perfil › Consentimentos.',
                  style: AppTypography.small,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Ativar lembretes neste aparelho', style: AppTypography.body),
                  value: reminders,
                  onChanged: (bool v) => setSheet(() => reminders = v),
                ),
                const SizedBox(height: 8),
                PrimeButton(label: 'Aceitar e ativar', onPressed: () async => Navigator.of(ctx).pop(true)),
                const SizedBox(height: 6),
                PrimeButton(label: 'Agora não', variant: PrimeButtonVariant.ghost, onPressed: () async => Navigator.of(ctx).pop(false)),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok == true) {
      _reminders = reminders;
      await widget.onEnable(reminders);
    }
  }

  @override
  Widget build(BuildContext context) {
    return EmptyView(
      icon: Icons.check_circle_outline_rounded,
      title: 'Sua rotina ainda não está ativa',
      body: 'Check-ins diários, sequência, metas e lembretes para você aproveitar cada produto da caixa.',
      action: PrimeButton(label: 'Ativar rotina', expanded: false, onPressed: _openSheet),
    );
  }
}
