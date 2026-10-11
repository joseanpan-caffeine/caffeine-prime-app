import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/models/capabilities.dart';
import '../../api/models/catalog.dart';
import '../../api/models/common.dart';
import '../../api/models/dashboard.dart';
import '../../api/models/editing.dart';
import '../../api/models/subscription.dart';
import '../../core/formatting.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/alert_card.dart';
import '../../core/widgets/capability_gate.dart';
import '../../core/widgets/prime_button.dart';
import '../../core/widgets/product_thumb.dart';
import '../../core/widgets/quantity_stepper.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/surface_card.dart';
import '../../data/providers.dart';
import 'box_editor_controller.dart';

/// Editor de caixa: abas por categoria, stepper por item, menu de ação
/// (trocar sabor / recorrência / remover), brindes, próximo ciclo, cupom e
/// resumo fixo com prévia de preço da API (debounce).
class BoxEditorScreen extends ConsumerStatefulWidget {
  const BoxEditorScreen({super.key});

  @override
  ConsumerState<BoxEditorScreen> createState() => _BoxEditorScreenState();
}

class _BoxEditorScreenState extends ConsumerState<BoxEditorScreen> {
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Dashboard> dashboard = ref.watch(dashboardProvider);
    final AsyncValue<Catalog> catalog = ref.watch(catalogProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Editar caixa')),
      body: dashboard.when(
        loading: () => const LoadingView(),
        error: (Object e, _) => ErrorView(error: e, onRetry: () async => ref.invalidate(dashboardProvider)),
        data: (Dashboard d) {
          final Subscription? s = d.subscription;
          if (s == null) {
            return const EmptyView(title: 'Sem assinatura ativa', body: 'Assine o Prime para montar sua caixa.');
          }
          final Capability canEdit = d.capabilities.canEdit;
          if (!canEdit.allowed) return _BlockedView(capability: canEdit);

          return catalog.when(
            loading: () => const LoadingView(message: 'Carregando catálogo…'),
            error: (Object e, _) => ErrorView(error: e, onRetry: () async => ref.invalidate(catalogProvider)),
            data: (Catalog c) {
              if (!_initialized) {
                _initialized = true;
                final String? add = GoRouterState.of(context).uri.queryParameters['add'];
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref.read(boxEditorProvider.notifier).initFrom(s, addHandle: add);
                });
              }
              return _EditorBody(subscription: s, catalog: c, canEdit: canEdit);
            },
          );
        },
      ),
    );
  }
}

class _BlockedView extends StatelessWidget {
  const _BlockedView({required this.capability});

  final Capability capability;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppDims.pageMargin),
      children: <Widget>[
        AlertCard(
          tone: AlertTone.neutral,
          icon: Icons.lock_clock_rounded,
          title: 'Por que não consigo editar minha caixa agora?',
          body: capabilityHint(capability),
        ),
        const SizedBox(height: 12),
        if (capability.reason == CapabilityReason.editWindowClosed)
          Text(
            'Perto da cobrança, sua caixa já entra em preparo. Assim que a próxima cobrança acontecer, a edição reabre '
            'e você pode trocar sabores, quantidades e tamanhos para o ciclo seguinte.',
            style: AppTypography.body,
          ),
        const SizedBox(height: 16),
        PrimeButton(label: 'Voltar', variant: PrimeButtonVariant.secondary, onPressed: () async => context.pop()),
      ],
    );
  }
}

class _EditorBody extends ConsumerStatefulWidget {
  const _EditorBody({required this.subscription, required this.catalog, required this.canEdit});

  final Subscription subscription;
  final Catalog catalog;
  final Capability canEdit;

  @override
  ConsumerState<_EditorBody> createState() => _EditorBodyState();
}

class _EditorBodyState extends ConsumerState<_EditorBody> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final TextEditingController _coupon = TextEditingController();

  List<String> get _tabNames => <String>['Minha caixa', ...widget.catalog.categories, 'Brindes e opções'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _tabNames.length, vsync: this);
    _coupon.text = widget.subscription.discount.code ?? '';
  }

  @override
  void dispose() {
    _tabs.dispose();
    _coupon.dispose();
    super.dispose();
  }

  CatalogProduct? _product(String handle) {
    for (final CatalogProduct p in widget.catalog.products) {
      if (p.handle == handle) return p;
    }
    return null;
  }

  ProductItem? _subscriptionItem(String handle) {
    for (final ProductItem i in widget.subscription.items) {
      if (i.handle == handle) return i;
    }
    return null;
  }

  Future<void> _confirm() async {
    final BoxEditorController ctrl = ref.read(boxEditorProvider.notifier);
    final BoxEditorState st = ref.read(boxEditorProvider);
    final bool planChanged = st.frequency != st.originalFrequency;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Confirmar edição da assinatura?'),
        content: Text(
          planChanged
              ? 'Você está trocando de plano. Uma nova assinatura começa na próxima cobrança e a atual é encerrada automaticamente.'
              : st.nextCycleOnly
                  ? 'As alterações valem só para a próxima caixa.'
                  : 'As alterações valem a partir da próxima cobrança.',
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Revisar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final ScheduledChange result = await ctrl.confirm();
      if (!mounted) return;
      showSuccessToast(
        context,
        'Caixa atualizada!',
        body: 'Vale a partir de ${Fmt.date(result.appliesAt)}. O valor pode levar instantes para refletir.',
      );
      context.pop();
    } catch (e) {
      if (mounted) showErrorToast(context, e, title: 'Não foi possível salvar');
    }
  }

  @override
  Widget build(BuildContext context) {
    final BoxEditorState st = ref.watch(boxEditorProvider);
    if (!st.initialized) return const LoadingView();

    return Column(
      children: <Widget>[
        Container(
          color: AppColors.bgSurface,
          child: TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.brandGold,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.brandGold,
            labelStyle: AppTypography.smallBold,
            tabs: _tabNames.map((n) => Tab(text: n)).toList(),
          ),
        ),
        if (widget.canEdit.closesAt != null)
          Container(
            width: double.infinity,
            color: AppColors.infoSoft,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              'Edição disponível até ${Fmt.dateTime(widget.canEdit.closesAt)}',
              style: AppTypography.caption.copyWith(color: AppColors.info),
            ),
          ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: <Widget>[
              _myBoxTab(st),
              for (final String cat in widget.catalog.categories) _categoryTab(cat, st),
              _optionsTab(st),
            ],
          ),
        ),
        _SummaryBar(state: st, onConfirm: _confirm),
      ],
    );
  }

  Widget _myBoxTab(BoxEditorState st) {
    if (st.items.isEmpty) {
      return EmptyView(
        title: 'Sua caixa está vazia',
        body: 'Escolha produtos nas abas acima.',
        icon: Icons.inventory_2_outlined,
        action: PrimeButton(
          label: 'Ver produtos',
          expanded: false,
          onPressed: () async => _tabs.animateTo(1),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(AppDims.pageMargin),
      children: <Widget>[
        for (final BoxItemInput input in st.items) ...<Widget>[
          _ItemRow(
            input: input,
            product: _product(input.handle),
            fallback: _subscriptionItem(input.handle),
            preview: st.preview.valueOrNull,
            onQuantity: (int q) => ref.read(boxEditorProvider.notifier).setQuantity(input.handle, q),
            onEdit: () => _openActionSheet(input),
          ),
          const SizedBox(height: 10),
        ],
        if (st.allSixtyDays)
          const AlertCard(
            tone: AlertTone.warning,
            title: 'Pelo menos um item precisa ser de todo ciclo',
            body: 'Itens com recorrência de 60 dias alternam entre caixas; a assinatura precisa de um item fixo.',
          ),
      ],
    );
  }

  Widget _categoryTab(String category, BoxEditorState st) {
    final List<CatalogProduct> products = widget.catalog.products.where((p) => p.category == category).toList();
    return ListView.separated(
      padding: const EdgeInsets.all(AppDims.pageMargin),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int i) {
        final CatalogProduct p = products[i];
        final int qty = st.quantityOf(p.handle);
        return SurfaceCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              ProductThumb(imageUrl: p.imageUrl, handle: p.handle, title: p.title, size: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(p.title, style: AppTypography.bodyBold, maxLines: 2, overflow: TextOverflow.ellipsis),
                    Text(
                      Fmt.join(<String?>[
                        Fmt.money(p.price),
                        if (!p.inStock) 'Esgotado',
                        if (p.flavors != null && p.flavors!.isNotEmpty) '${p.flavors!.length} sabores',
                      ]),
                      style: AppTypography.small,
                    ),
                  ],
                ),
              ),
              QuantityStepper(
                value: qty,
                min: 0,
                max: p.maxQuantity,
                enabled: p.inStock || qty > 0,
                onChanged: (int q) {
                  final int min = p.minQuantity;
                  // Ao adicionar, respeita a quantidade mínima do catálogo.
                  final int next = (q > 0 && q < min) ? (qty == 0 ? min : 0) : q;
                  ref.read(boxEditorProvider.notifier).setQuantity(p.handle, next);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _optionsTab(BoxEditorState st) {
    final List<CatalogGift> gifts = widget.catalog.gifts.where((g) => g.availableFor(st.frequency)).toList();
    final List<Plan> plans = widget.catalog.plans;
    return ListView(
      padding: const EdgeInsets.all(AppDims.pageMargin),
      children: <Widget>[
        if (gifts.isNotEmpty) ...<Widget>[
          Text('Brindes da próxima caixa', style: AppTypography.h3),
          const SizedBox(height: 4),
          Text('Escolha os brindes disponíveis para o seu plano.', style: AppTypography.small),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: gifts.map((g) {
              final bool selected = st.giftHandles.contains(g.handle);
              return FilterChip(
                selected: selected,
                label: Text(g.title),
                avatar: ProductThumb(imageUrl: g.imageUrl, handle: g.handle, title: g.title, size: 24, radius: 12),
                onSelected: (_) => ref.read(boxEditorProvider.notifier).toggleGift(g.handle),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
        Text('Cupom', style: AppTypography.h3),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _coupon,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(hintText: 'Código do cupom'),
              ),
            ),
            const SizedBox(width: 8),
            PrimeButton(
              label: 'Aplicar',
              expanded: false,
              variant: PrimeButtonVariant.secondary,
              onPressed: () async => ref.read(boxEditorProvider.notifier).setCoupon(_coupon.text),
            ),
          ],
        ),
        if (st.preview.valueOrNull?.couponApplied != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Cupom aplicado: ${st.preview.valueOrNull!.couponApplied}',
                style: AppTypography.small.copyWith(color: AppColors.successText)),
          ),
        const SizedBox(height: 20),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Só na próxima caixa', style: AppTypography.bodyBold),
          subtitle: Text('As alterações valem para um ciclo e depois a caixa volta ao normal.', style: AppTypography.small),
          value: st.nextCycleOnly,
          onChanged: (bool v) => ref.read(boxEditorProvider.notifier).setNextCycleOnly(v),
        ),
        if (plans.isNotEmpty) ...<Widget>[
          const SizedBox(height: 20),
          Text('Plano (fidelidade)', style: AppTypography.h3),
          const SizedBox(height: 4),
          Text(
            'Trocar o plano cria uma nova assinatura a partir da próxima cobrança (o id da assinatura muda).',
            style: AppTypography.small,
          ),
          const SizedBox(height: 8),
          for (final Plan p in plans)
            RadioListTile<Frequency>(
              contentPadding: EdgeInsets.zero,
              value: p.frequency,
              groupValue: st.frequency,
              title: Text(p.name.isNotEmpty ? p.name : p.frequency.label, style: AppTypography.bodyBold),
              subtitle: Text(
                Fmt.join(<String?>[
                  '${Fmt.percent(p.discountPercentage)} de desconto',
                  p.commitmentMonths > 0 ? '${p.commitmentMonths} meses de fidelidade' : 'sem fidelidade',
                  p.pauseCredits > 0 ? '${p.pauseCredits} pausa(s)' : null,
                  p.highlight,
                ]),
                style: AppTypography.small,
              ),
              onChanged: (Frequency? f) {
                if (f != null) ref.read(boxEditorProvider.notifier).setFrequency(f);
              },
            ),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  Future<void> _openActionSheet(BoxItemInput input) async {
    final CatalogProduct? product = _product(input.handle);
    final bool isSixty = input.recurrence != null && input.recurrence!.isSixtyDays;
    final List<CatalogFlavor> flavors = product?.flavors ?? const <CatalogFlavor>[];
    // Alternativas de "tamanho": produtos da mesma categoria com título parecido.
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (flavors.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.swap_horiz_rounded, color: AppColors.brandGold),
                title: const Text('Trocar sabor'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickFlavor(input, flavors);
                },
              ),
            ListTile(
              leading: const Icon(Icons.autorenew_rounded, color: AppColors.brandGold),
              title: Text(isSixty ? 'Voltar para todo ciclo' : 'Trocar para recorrência de 60 dias'),
              subtitle: Text(isSixty ? 'Hoje: alterna a cada caixa' : 'O item entra em caixas alternadas'),
              onTap: () {
                Navigator.of(ctx).pop();
                ref.read(boxEditorProvider.notifier).toggleSixtyDays(input.handle);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
              title: Text('Remover item', style: AppTypography.bodyBold.copyWith(color: AppColors.danger)),
              onTap: () {
                Navigator.of(ctx).pop();
                ref.read(boxEditorProvider.notifier).remove(input.handle);
              },
            ),
            const Divider(),
            ListTile(
              title: const Center(child: Text('Cancelar')),
              onTap: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFlavor(BoxItemInput input, List<CatalogFlavor> flavors) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('Escolha o sabor', style: AppTypography.h3),
            ),
            for (final CatalogFlavor f in flavors)
              ListTile(
                title: Text(f.title),
                subtitle: f.inStock ? null : const Text('Esgotado'),
                enabled: f.inStock,
                trailing: f.handle == input.handle ? const Icon(Icons.check_rounded, color: AppColors.success) : null,
                onTap: () {
                  Navigator.of(ctx).pop();
                  ref.read(boxEditorProvider.notifier).replaceHandle(input.handle, f.handle);
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Linha de item da caixa: thumb, nome, info, recorrência, stepper e "Editar".
class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.input,
    required this.product,
    required this.fallback,
    required this.preview,
    required this.onQuantity,
    required this.onEdit,
  });

  final BoxItemInput input;
  final CatalogProduct? product;
  final ProductItem? fallback;
  final PricePreview? preview;
  final ValueChanged<int> onQuantity;
  final VoidCallback onEdit;

  PricePreviewItem? get _previewItem {
    if (preview == null) return null;
    for (final PricePreviewItem i in preview!.items) {
      if (i.handle == input.handle) return i;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final String title = product?.title ?? fallback?.title ?? input.handle;
    final String? imageUrl = product?.imageUrl ?? fallback?.imageUrl;
    final PricePreviewItem? pi = _previewItem;
    final bool sixty = input.recurrence != null && input.recurrence!.isSixtyDays;
    final String priceLine = pi != null
        ? '${Fmt.money(pi.finalUnitPrice)}/un.${pi.discountPercentage > 0 ? ' · ${Fmt.percent(pi.discountPercentage)} OFF' : ''}'
        : (fallback != null ? '${Fmt.money(fallback!.finalPrice)}/un.' : (product != null ? Fmt.money(product!.price) : ''));

    return SurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              ProductThumb(imageUrl: imageUrl, handle: input.handle, title: title, flavor: fallback?.flavor, size: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: AppTypography.bodyBold, maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (fallback?.flavor != null) Text(fallback!.flavor!, style: AppTypography.small),
                    Text(priceLine, style: AppTypography.small),
                    if (sixty)
                      Row(
                        children: <Widget>[
                          const Icon(Icons.autorenew_rounded, size: 14, color: AppColors.brandGold),
                          const SizedBox(width: 4),
                          Text('Recorrência de 60 dias', style: AppTypography.caption.copyWith(color: AppColors.brandGold)),
                        ],
                      ),
                    if (fallback?.cyclesLeft != null)
                      Text('Item temporário: ${fallback!.cyclesLeft} ciclo(s)', style: AppTypography.caption),
                  ],
                ),
              ),
              PrimeButton(label: 'Editar', small: true, expanded: false, onPressed: () async => onEdit()),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              QuantityStepper(value: input.quantity, min: 0, max: product?.maxQuantity ?? 99, onChanged: onQuantity),
            ],
          ),
        ],
      ),
    );
  }
}

/// Resumo fixo inferior: total (API), itens, economia, alterações e confirmar.
class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.state, required this.onConfirm});

  final BoxEditorState state;
  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<PricePreview?> preview = state.preview;
    final PricePreview? p = preview.valueOrNull;
    final bool loading = preview.isLoading;
    final bool canConfirm = state.hasChanges && state.items.isNotEmpty && !state.allSixtyDays && !loading && !state.submitting;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        boxShadow: <BoxShadow>[BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -2))],
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (loading)
                      Text('Calculando…', style: AppTypography.small)
                    else if (preview.hasError)
                      Text('Não foi possível calcular o valor', style: AppTypography.small.copyWith(color: AppColors.danger))
                    else if (p != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Text('Total ${Fmt.money(p.total)}/mês', style: AppTypography.h3),
                          const SizedBox(width: 8),
                          if (p.totalDiscount.amount > 0)
                            Text(
                              Fmt.money(p.subtotal),
                              style: AppTypography.small.copyWith(decoration: TextDecoration.lineThrough, color: AppColors.textMuted),
                            ),
                        ],
                      )
                    else
                      Text('Adicione itens para ver o valor', style: AppTypography.small),
                    Text('${state.totalUnits} ${state.totalUnits == 1 ? 'item' : 'itens'}', style: AppTypography.caption),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  if (p != null && p.totalDiscount.amount > 0)
                    StatusBadge(label: 'ECONOMIZE ${Fmt.money(p.totalDiscount)}', tone: BadgeTone.success, pill: false),
                  if (state.changesCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(Icons.circle, size: 8, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text(
                            '${state.changesCount} ${state.changesCount == 1 ? 'alteração' : 'alterações'}',
                            style: AppTypography.caption.copyWith(color: AppColors.warning),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (p != null && p.warnings.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(p.warnings.join(' '), style: AppTypography.caption.copyWith(color: AppColors.warningText)),
            ),
          const SizedBox(height: 10),
          PrimeButton(
            label: 'Confirmar edição da assinatura',
            variant: PrimeButtonVariant.success,
            loading: state.submitting,
            onPressed: canConfirm ? onConfirm : null,
          ),
        ],
      ),
    );
  }
}
