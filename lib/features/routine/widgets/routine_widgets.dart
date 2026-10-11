import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../api/models/routine.dart';
import '../../../core/formatting.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/product_thumb.dart';
import '../../../core/widgets/surface_card.dart';

/// Linha de check-in do dia: toque marca, toque de novo desfaz.
class CheckInRow extends StatelessWidget {
  const CheckInRow({
    super.key,
    required this.item,
    required this.done,
    required this.busy,
    required this.onToggle,
    required this.onReminder,
  });

  final RoutineItem item;
  final bool done;
  final bool busy;
  final VoidCallback onToggle;
  final VoidCallback onReminder;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(12),
      onTap: busy ? null : onToggle,
      child: Row(
        children: <Widget>[
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? AppColors.success : Colors.transparent,
              border: Border.all(color: done ? AppColors.success : AppColors.borderStrong, width: 2),
            ),
            child: busy
                ? const Padding(padding: EdgeInsets.all(5), child: CircularProgressIndicator(strokeWidth: 2))
                : done
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
          ),
          const SizedBox(width: 12),
          ProductThumb(imageUrl: item.imageUrl, handle: item.productHandle, title: item.title, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.title,
                  style: AppTypography.bodyBold.copyWith(
                    decoration: done ? TextDecoration.lineThrough : null,
                    color: done ? AppColors.textMuted : AppColors.textPrimary,
                  ),
                ),
                Text(
                  Fmt.join(<String?>[
                    item.slot.label,
                    if (item.reminderEnabled) 'lembrete ${item.reminderTime ?? item.slot.defaultTime}',
                    if (item.dosesPerDay > 1) '${item.dosesPerDay} doses/dia',
                  ]),
                  style: AppTypography.caption,
                ),
                if (item.usageHint != null && item.usageHint!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(item.usageHint!, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.caption.copyWith(color: AppColors.brandGold)),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Lembrete',
            icon: Icon(
              item.reminderEnabled ? Icons.alarm_on_rounded : Icons.alarm_add_outlined,
              color: item.reminderEnabled ? AppColors.brandGold : AppColors.textMuted,
            ),
            onPressed: onReminder,
          ),
        ],
      ),
    );
  }
}

/// Sequência atual + anel de meta semanal.
class StreakCard extends StatelessWidget {
  const StreakCard({super.key, required this.summary, required this.weeklyGoalDays, required this.onGoalTap});

  final RoutineSummary summary;
  final int weeklyGoalDays;
  final VoidCallback onGoalTap;

  @override
  Widget build(BuildContext context) {
    final double progress = summary.weekCompletion.clamp(0, 1).toDouble();
    return SurfaceCard(
      color: AppColors.brandDark,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(Icons.local_fire_department_rounded, color: AppColors.brandGold, size: 28),
                    const SizedBox(width: 6),
                    Text('${summary.currentStreakDays}', style: AppTypography.display.copyWith(color: Colors.white)),
                  ],
                ),
                Text(
                  summary.currentStreakDays == 1 ? 'dia seguido' : 'dias seguidos',
                  style: AppTypography.small.copyWith(color: AppColors.brandPrimary),
                ),
                const SizedBox(height: 6),
                Text('Melhor sequência: ${summary.longestStreakDays} dias', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                Text('Hoje: ${(summary.today.completion * 100).round()}% concluído', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          InkWell(
            onTap: onGoalTap,
            borderRadius: BorderRadius.circular(60),
            child: SizedBox(
              width: 96,
              height: 96,
              child: CustomPaint(
                painter: _RingPainter(progress: progress, color: AppColors.brandGold, track: AppColors.brandDark2),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text('${(progress * 100).round()}%', style: AppTypography.h3.copyWith(color: Colors.white)),
                      Text('meta $weeklyGoalDays/7', style: AppTypography.caption.copyWith(color: AppColors.brandPrimary)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color, required this.track});

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 8;
    final Rect rect = Offset.zero & size;
    final Rect inner = rect.deflate(stroke / 2);
    final Paint trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final Paint progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(inner, 0, 2 * math.pi, false, trackPaint);
    canvas.drawArc(inner, -math.pi / 2, 2 * math.pi * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress || old.color != color;
}

/// Heatmap dos últimos 28 dias (4 semanas × 7).
class Heatmap28 extends StatelessWidget {
  const Heatmap28({super.key, required this.days});

  final List<DayCompletionEntry> days;

  Color _color(double c) {
    if (c <= 0) return AppColors.bgMuted;
    if (c < 0.34) return AppColors.successSoft;
    if (c < 0.67) return AppColors.successBadge;
    if (c < 1) return AppColors.success;
    return AppColors.successDeep;
  }

  @override
  Widget build(BuildContext context) {
    // Garante 28 posições (preenche à esquerda com vazios).
    final List<DayCompletionEntry> list = List<DayCompletionEntry>.from(days);
    while (list.length < 28) {
      list.insert(0, const DayCompletionEntry(date: '', completion: -1));
    }
    final List<DayCompletionEntry> last = list.length > 28 ? list.sublist(list.length - 28) : list;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Últimos 28 dias', style: AppTypography.bodyBold),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final double cell = ((c.maxWidth - 6 * 6) / 7).clamp(16, 44).toDouble();
              return Wrap(
                spacing: 6,
                runSpacing: 6,
                children: last.map((d) {
                  final DateTime? date = d.date.isEmpty ? null : DateTime.tryParse(d.date);
                  return Tooltip(
                    message: date == null ? '' : '${Fmt.weekdayShort(date)} ${Fmt.dayMonth(d.date)} · ${(d.completion.clamp(0, 1) * 100).round()}%',
                    child: Container(
                      width: cell,
                      height: cell,
                      decoration: BoxDecoration(
                        color: d.completion < 0 ? Colors.transparent : _color(d.completion),
                        borderRadius: BorderRadius.circular(4),
                        border: d.completion < 0 ? Border.all(color: AppColors.border) : null,
                      ),
                      alignment: Alignment.center,
                      child: date == null
                          ? null
                          : Text('${date.day}', style: AppTypography.caption.copyWith(fontSize: 9, color: d.completion >= 0.67 ? Colors.white : AppColors.textMuted)),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Text('Menos', style: AppTypography.caption),
              const SizedBox(width: 6),
              for (final double v in <double>[0, 0.3, 0.6, 0.9, 1])
                Container(width: 12, height: 12, margin: const EdgeInsets.only(right: 3), decoration: BoxDecoration(color: _color(v), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 3),
              Text('Mais', style: AppTypography.caption),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Suas latas duram até …": previsão de estoque × próxima caixa.
class StockForecastCard extends StatelessWidget {
  const StockForecastCard({super.key, required this.forecast, required this.titleFor});

  final List<StockForecast> forecast;
  final String Function(String handle) titleFor;

  @override
  Widget build(BuildContext context) {
    if (forecast.isEmpty) return const SizedBox.shrink();
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.inventory_2_outlined, color: AppColors.brandGold, size: 20),
              const SizedBox(width: 8),
              Text('Previsão de estoque', style: AppTypography.bodyBold),
            ],
          ),
          const SizedBox(height: 8),
          for (final StockForecast f in forecast)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: <Widget>[
                  ProductThumb(handle: f.productHandle, title: titleFor(f.productHandle), size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(titleFor(f.productHandle), style: AppTypography.smallBold),
                        Text(
                          f.runsOutAt != null
                              ? 'Suas doses duram até ${Fmt.date(f.runsOutAt)} (${f.dosesLeft} restantes)'
                              : '${f.dosesLeft} doses restantes',
                          style: AppTypography.caption,
                        ),
                        if (f.nextBoxAt != null)
                          Text(
                            _compare(f),
                            style: AppTypography.caption.copyWith(color: _late(f) ? AppColors.warningText : AppColors.successText),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  bool _late(StockForecast f) {
    final DateTime? out = Fmt.parseWall(f.runsOutAt);
    final DateTime? next = Fmt.parseWall(f.nextBoxAt);
    if (out == null || next == null) return false;
    return out.isBefore(next);
  }

  String _compare(StockForecast f) {
    if (f.runsOutAt == null) return 'Próxima caixa em ${Fmt.date(f.nextBoxAt)}';
    return _late(f)
        ? 'Acaba antes da próxima caixa (${Fmt.date(f.nextBoxAt)}): considere aumentar a quantidade.'
        : 'Chega nova caixa em ${Fmt.date(f.nextBoxAt)} antes de acabar. Está sobrando? Reduza ou use 60 dias.';
  }
}
