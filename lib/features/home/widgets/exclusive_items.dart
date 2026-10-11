import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/models/capabilities.dart';
import '../../../api/models/catalog.dart';
import '../../../api/models/subscription.dart';
import '../../../core/formatting.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/capability_gate.dart';
import '../../../core/widgets/prime_button.dart';
import '../../../core/widgets/product_thumb.dart';
import '../../../core/widgets/section_list.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../data/providers.dart';
import '../../../router.dart';

/// "Complete sua rotina com itens exclusivos": produtos do catálogo que ainda
/// não estão na caixa. Preços e desconto vêm do catálogo/assinatura (API).
class ExclusiveItemsCarousel extends ConsumerWidget {
  const ExclusiveItemsCarousel({super.key, required this.subscription, required this.canEdit});

  final Subscription subscription;
  final Capability canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Catalog> catalog = ref.watch(catalogProvider);
    final Catalog? c = catalog.valueOrNull;
    if (c == null) return const SizedBox.shrink();

    final Set<String> inBox = subscription.items.map((i) => i.handle).toSet();
    final List<CatalogProduct> candidates =
        c.products.where((p) => !inBox.contains(p.handle) && p.inStock).take(10).toList();
    if (candidates.isEmpty) return const SizedBox.shrink();

    // Percentual da assinatura (API), só para o badge informativo.
    final double pct = subscription.discount.temporaryPercentage ?? subscription.discount.percentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDims.pageMargin),
          child: SectionTitle(
            icon: Icons.bolt_rounded,
            title: 'Complete sua rotina com itens exclusivos',
            subtitle: 'Adicione à caixa com o desconto Prime',
          ),
        ),
        SizedBox(
          height: 300,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppDims.pageMargin),
            itemCount: candidates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (BuildContext context, int index) {
              final CatalogProduct p = candidates[index];
              return SizedBox(
                width: 160,
                child: SurfaceCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const StatusBadge(label: 'EXCLUSIVO PRIME', tone: BadgeTone.gold, pill: false),
                      const SizedBox(height: 8),
                      Center(child: ProductThumb(imageUrl: p.imageUrl, handle: p.handle, title: p.title, size: 84)),
                      const SizedBox(height: 8),
                      Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.smallBold),
                      Text(p.category, style: AppTypography.caption),
                      const Spacer(),
                      // Sem recalcular desconto no app (contexto §12): mostramos o
                      // preço cheio do catálogo e o % da assinatura; o valor final
                      // vem do preview da API no editor.
                      Text('${Fmt.money(p.price)} compra única', style: AppTypography.caption),
                      Row(
                        children: <Widget>[
                          if (pct > 0)
                            StatusBadge(label: '${Fmt.percent(pct)} OFF NA CAIXA', tone: BadgeTone.success, pill: false),
                        ],
                      ),
                      const SizedBox(height: 8),
                      PrimeButton(
                        label: 'Adicionar à caixa',
                        small: true,
                        onPressed: () async => guardCapability(
                          context,
                          canEdit,
                          () => context.push('${Routes.box}?add=${Uri.encodeQueryComponent(p.handle)}'),
                          title: 'Edição da caixa',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
