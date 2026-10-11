import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../api/models/capabilities.dart';
import '../../../api/models/common.dart';
import '../../../api/models/dashboard.dart';
import '../../../api/models/subscription.dart';
import '../../../core/formatting.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/capability_gate.dart';
import '../../../core/widgets/product_thumb.dart';
import '../../../core/widgets/section_list.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../router.dart';

/// "Minhas próximas caixas": carrossel de cards escuros. Só a primeira data
/// (`nextBillingAt`) é confirmada; as seguintes são "Previsão" (+30 dias cada),
/// porque o ciclo é de 30 dias, não um dia fixo do mês (contexto §6.3).
class NextBoxesCarousel extends StatefulWidget {
  const NextBoxesCarousel({super.key, required this.dashboard});

  final Dashboard dashboard;

  @override
  State<NextBoxesCarousel> createState() => _NextBoxesCarouselState();
}

class _NextBoxesCarouselState extends State<NextBoxesCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.92);
  int _page = 0;
  static const int _count = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    final int p = page.clamp(0, _count - 1).toInt();
    _controller.animateToPage(p, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final Subscription? s = widget.dashboard.subscription;
    if (s == null) return const SizedBox.shrink();
    final DateTime? next = Fmt.parseWall(s.nextBillingAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDims.pageMargin),
          child: SectionTitle(
            icon: Icons.view_in_ar_rounded,
            title: 'Minhas próximas caixas',
            subtitle: 'Acompanhe seus pedidos mês a mês',
            trailing: Row(
              children: <Widget>[
                _ArrowButton(icon: Icons.chevron_left_rounded, onTap: _page > 0 ? () => _goTo(_page - 1) : null),
                const SizedBox(width: 6),
                _ArrowButton(
                  icon: Icons.chevron_right_rounded,
                  dark: true,
                  onTap: _page < _count - 1 ? () => _goTo(_page + 1) : null,
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 360,
          child: PageView.builder(
            controller: _controller,
            itemCount: _count,
            onPageChanged: (int i) => setState(() => _page = i),
            itemBuilder: (BuildContext context, int index) {
              final DateTime? date = next?.add(Duration(days: 30 * index));
              return Padding(
                padding: const EdgeInsets.only(left: AppDims.pageMargin, right: 4),
                child: _NextBoxCard(
                  dashboard: widget.dashboard,
                  subscription: s,
                  date: date,
                  confirmed: index == 0,
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppDims.pageMargin, 4, AppDims.pageMargin, 0),
          child: Text(
            'A cobrança acontece a cada 30 dias, por isso as datas seguintes são previsão.',
            style: AppTypography.caption,
          ),
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, this.onTap, this.dark = false});

  final IconData icon;
  final VoidCallback? onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: dark && enabled ? AppColors.textPrimary : AppColors.bgMuted,
        ),
        child: Icon(icon, size: 18, color: dark && enabled ? Colors.white : AppColors.textSecondary),
      ),
    );
  }
}

class _NextBoxCard extends StatelessWidget {
  const _NextBoxCard({
    required this.dashboard,
    required this.subscription,
    required this.date,
    required this.confirmed,
  });

  final Dashboard dashboard;
  final Subscription subscription;
  final DateTime? date;
  final bool confirmed;

  @override
  Widget build(BuildContext context) {
    final bool muted = dashboard.capabilities.hasPendingBill;
    final Color fg = muted ? AppColors.textPrimary : Colors.white;
    final Color fgSoft = muted ? AppColors.textMuted : AppColors.brandPrimary;
    final Capability edit = dashboard.capabilities.canEdit;
    final List<ProductItem> items = subscription.items.where((i) => !i.gift).toList();
    final List<ProductItem> gifts = subscription.items.where((i) => i.gift).toList();
    final String dateLabel = date == null ? '—' : Fmt.dayMonthLongOf(date!);

    return DarkCard(
      muted: muted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(confirmed ? 'Data de pagamento' : 'Previsão de pagamento', style: AppTypography.caption.copyWith(color: fgSoft)),
                    Text(dateLabel, style: AppTypography.h3.copyWith(color: fg)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text('Valor total', style: AppTypography.caption.copyWith(color: fgSoft)),
                  Text(Fmt.money(subscription.total), style: AppTypography.h3.copyWith(color: fg)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  for (final ProductItem item in items)
                    Opacity(
                      opacity: item.recurrence == ItemRecurrence.off ? 0.45 : 1,
                      child: ProductThumb(
                        imageUrl: item.imageUrl,
                        handle: item.handle,
                        title: item.title,
                        flavor: item.flavor,
                        size: 72,
                        quantity: item.quantity,
                        showEditPencil: edit.allowed,
                        background: muted ? AppColors.bgMuted : AppColors.brandDark2,
                      ),
                    ),
                  InkWell(
                    onTap: () => guardCapability(context, edit, () => context.push(Routes.box), title: 'Edição da caixa'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: muted ? AppColors.bgMuted : AppColors.brandDark2,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.brandGold, width: 1, style: BorderStyle.solid),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(Icons.add, color: AppColors.brandGold, size: 20),
                          Text('Adicionar\nitens', textAlign: TextAlign.center, style: AppTypography.badge.copyWith(color: AppColors.brandGold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (gifts.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(child: Text('Seus brindes da próxima caixa', style: AppTypography.smallBold.copyWith(color: fg))),
                Icon(Icons.chevron_right_rounded, color: fgSoft, size: 18),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: gifts
                  .take(4)
                  .map((g) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ProductThumb(
                          imageUrl: g.imageUrl,
                          handle: g.handle,
                          title: g.title,
                          size: 56,
                          background: muted ? AppColors.bgMuted : AppColors.brandDark2,
                        ),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          Center(
            child: _GradientButton(
              label: 'Editar caixa',
              enabled: !muted,
              onTap: () => guardCapability(context, edit, () => context.push(Routes.box), title: 'Edição da caixa'),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Icon(Icons.info_outline_rounded, size: 14, color: fgSoft),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  edit.allowed
                      ? (edit.closesAt != null
                          ? 'Você pode alterar sua caixa até ${Fmt.dayMonth(edit.closesAt)}'
                          : 'Você pode alterar sua caixa')
                      : capabilityHint(edit),
                  style: AppTypography.caption.copyWith(color: fgSoft),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Botão dourado-gradiente do card escuro.
class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onTap, this.enabled = true});

  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppDims.radiusButton),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDims.radiusButton),
          gradient: enabled
              ? const LinearGradient(colors: <Color>[AppColors.brandGradientStart, AppColors.brandGradientEnd])
              : null,
          color: enabled ? null : AppColors.bgMuted,
        ),
        child: Text(label, style: AppTypography.bodyBold.copyWith(color: enabled ? AppColors.brandDark : AppColors.textMuted)),
      ),
    );
  }
}
