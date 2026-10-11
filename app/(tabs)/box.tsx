import { useEffect, useMemo, useRef, useState } from 'react';
import { Pressable, StyleSheet, Switch, View } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import type { Catalog, CatalogProduct, ItemRecurrence, Subscription } from '@/api/contracts';
import { errorMessage } from '@/api/client';
import { useApplyDiscount, useCatalog, useDashboard, usePreview, useScheduleChange, useSetItemRecurrence, useSubscription } from '@/api/hooks';
import {
  AlertCard,
  AppHeader,
  Badge,
  BoxItemRow,
  Button,
  Card,
  CategoryTabs,
  EditSummaryBar,
  EmptyState,
  Input,
  ItemActionSheet,
  ProductImage,
  ProductTile,
  RadioRow,
  Screen,
  SectionHeader,
  Sheet,
  SkeletonCard,
  Stepper,
  Text,
  toast,
  type ItemAction,
} from '@/components';
import { type EditorItem, useBoxEditor } from '@/features/box/useBoxEditor';
import { formatDate, formatMoney } from '@/lib/format';
import { capabilityReasonLabel, frequencyLabel } from '@/lib/labels';
import { editUntilIso, formatShortDate } from '@/lib/prime';
import { colors, radius, space } from '@/theme';

export default function BoxScreen() {
  const router = useRouter();
  const dashboard = useDashboard();
  const subscription = useSubscription();
  const catalog = useCatalog();

  const loading = dashboard.isLoading || subscription.isLoading || catalog.isLoading;
  const refetch = () => {
    void dashboard.refetch();
    void subscription.refetch();
    void catalog.refetch();
  };

  const header = <AppHeader onMenu={() => router.push('/(tabs)')} onProfile={() => router.push('/(tabs)/profile')} />;

  if (loading) {
    return (
      <Screen header={header}>
        <SkeletonCard lines={2} />
        <SkeletonCard lines={4} />
      </Screen>
    );
  }

  const sub = subscription.data ?? dashboard.data?.subscription ?? null;
  if (!sub || !catalog.data || !dashboard.data) {
    return (
      <Screen header={header} onRefresh={refetch} refreshing={subscription.isRefetching}>
        <EmptyState title="Caixa indisponível" description={errorMessage(subscription.error ?? catalog.error ?? dashboard.error, 'Não há assinatura para editar.')} actionLabel="Tentar de novo" onAction={refetch} />
      </Screen>
    );
  }

  return <BoxEditor sub={sub} catalog={catalog.data} canEdit={dashboard.data.capabilities.canEdit} onRefresh={refetch} refreshing={subscription.isRefetching} header={header} />;
}

interface EditorProps {
  sub: Subscription;
  catalog: Catalog;
  canEdit: { allowed: boolean; reason?: Parameters<typeof capabilityReasonLabel>[0]; until?: string };
  onRefresh: () => void;
  refreshing: boolean;
  header: React.ReactNode;
}

const ALL = '__all__';

function BoxEditor({ sub, catalog, canEdit, onRefresh, refreshing, header }: EditorProps) {
  const router = useRouter();
  const params = useLocalSearchParams<{ add?: string }>();
  const editor = useBoxEditor(sub, catalog);
  const preview = usePreview(editor.previewRequest);
  const schedule = useScheduleChange();
  const setRecurrenceRemote = useSetItemRecurrence();
  const applyDiscount = useApplyDiscount();
  const [planSheet, setPlanSheet] = useState(false);
  const [flavorFor, setFlavorFor] = useState<CatalogProduct | null>(null);
  const [actionsFor, setActionsFor] = useState<CatalogProduct | null>(null);
  const [category, setCategory] = useState(ALL);
  const [coupon, setCoupon] = useState('');
  const [showOptions, setShowOptions] = useState(false);
  const addedParam = useRef<string | null>(null);

  const editable = canEdit.allowed;
  const byHandle = useMemo(() => new Map(editor.state.items.map((i) => [i.productHandle, i])), [editor.state.items]);
  const inBox = catalog.products.filter((p) => (byHandle.get(p.handle)?.quantity ?? 0) > 0);
  const available = catalog.products.filter((p) => (byHandle.get(p.handle)?.quantity ?? 0) === 0);
  const categories = useMemo(() => Array.from(new Set(catalog.products.map((p) => p.category))).filter(Boolean), [catalog.products]);
  const filteredAvailable = category === ALL ? available : available.filter((p) => p.category === category);
  const gifts = catalog.gifts.filter((g) => !g.requiresPlan || g.requiresPlan.includes(editor.state.frequency));
  const nextTier = [...catalog.discountTiers].sort((a, b) => a.minItems - b.minItems).find((t) => t.minItems > editor.totalUnits);
  const currentPlan = catalog.plans.find((p) => p.frequency === editor.state.frequency);
  const pct = preview.data?.appliedDiscountPercentage ?? sub.discount.percentage;

  // Deep link do dashboard: /(tabs)/box?add=<handle>
  useEffect(() => {
    const handle = params.add;
    if (!handle || !editable || addedParam.current === handle) return;
    const product = catalog.products.find((p) => p.handle === handle);
    if (product && (byHandle.get(product.handle)?.quantity ?? 0) === 0) {
      editor.setQuantity(product.handle, Math.max(1, product.minQuantity), product);
      toast.success(`${product.title} adicionado à caixa.`);
    }
    addedParam.current = handle;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [params.add, editable]);

  function unitPrice(item: EditorItem, product: CatalogProduct) {
    const p = preview.data?.items.find((i) => i.handle === item.handle);
    return p ? { final: p.finalUnitPrice, full: p.unitPrice, pct: p.discountPercentage } : { final: product.price, full: product.price, pct: 0 };
  }

  function toggleRecurrence(item: EditorItem) {
    const on = item.recurrence === null;
    const recurrence: ItemRecurrence = on ? 'on' : null;
    if (item.subscriptionItemId && !editor.dirty) {
      setRecurrenceRemote.mutate(
        { itemId: item.subscriptionItemId, recurrence },
        {
          onSuccess: () => toast.success(on ? 'Item passa a vir a cada 60 dias.' : 'Item volta a vir todo ciclo.'),
          onError: (e) => toast.error(errorMessage(e, 'Pelo menos um item precisa vir todo ciclo.')),
        },
      );
      return;
    }
    editor.setRecurrence(item.productHandle, recurrence);
  }

  function confirm() {
    if (!editor.schedulingRequest) return;
    if (editor.allRecurring) {
      toast.error('Pelo menos um item precisa vir todo ciclo.');
      return;
    }
    schedule.mutate(editor.schedulingRequest, {
      onSuccess: (change) => {
        toast.success(`Mudança agendada para ${formatDate(change.appliesAt)}.`);
        router.navigate('/(tabs)');
      },
      onError: (e) => toast.error(errorMessage(e, 'Não foi possível agendar a mudança.')),
    });
  }

  function submitCoupon() {
    const code = coupon.trim();
    if (!code) return;
    applyDiscount.mutate(code, {
      onSuccess: () => {
        toast.success('Cupom aplicado.');
        setCoupon('');
      },
      onError: (e) => toast.error(errorMessage(e, 'Cupom inválido.')),
    });
  }

  const total = preview.data?.total ?? sub.total;
  const subtotal = preview.data?.subtotal ?? sub.subtotal;
  const savings = subtotal.amount - total.amount;
  const canConfirm = editable && editor.dirty && !!editor.schedulingRequest && !preview.isError && !preview.isFetching;
  const addedCount = editor.activeItems.filter((i) => !i.subscriptionItemId).length;
  const removedCount = editor.state.items.filter((i) => i.subscriptionItemId && i.quantity === 0).length;

  const summaryLines = inBox.map((product) => {
    const item = byHandle.get(product.handle)!;
    const price = unitPrice(item, product);
    return { key: product.handle, label: `${product.title}${item.handle !== product.handle ? ` ${product.flavors?.find((f) => f.handle === item.handle)?.title ?? ''}` : ''}`, priceLabel: `${item.quantity}x ${formatMoney(price.final)}`, discountPercentage: price.pct || undefined };
  });

  const footer = (
    <EditSummaryBar
      totalLabel={formatMoney(total)}
      fullTotalLabel={subtotal.amount > total.amount ? formatMoney(subtotal) : undefined}
      itemsCount={editor.totalUnits}
      lines={summaryLines}
      savingsLabel={savings > 0 ? formatMoney(savings) : undefined}
      addedCount={addedCount}
      removedCount={removedCount}
      onConfirm={confirm}
      confirmDisabled={!canConfirm}
      confirmLoading={schedule.isPending}
      onDiscard={editor.dirty ? editor.reset : undefined}
      calculating={preview.isFetching}
      warnings={
        preview.data?.warnings.length || preview.isError ? (
          <View style={styles.warnings}>
            {preview.data?.warnings.map((w) => (
              <Text key={w} variant="caption" tone="warning">
                {w}
              </Text>
            ))}
            {preview.isError ? (
              <Text variant="caption" tone="danger">
                {errorMessage(preview.error, 'Não foi possível calcular o preço.')}
              </Text>
            ) : null}
          </View>
        ) : null
      }
    />
  );

  const actionsItem = actionsFor ? byHandle.get(actionsFor.handle) : undefined;
  const itemActions: ItemAction[] = actionsFor
    ? [
        ...(actionsFor.flavors && actionsFor.flavors.length > 0 ? [{ key: 'flavor', label: 'Trocar sabor', onPress: () => setFlavorFor(actionsFor) }] : []),
        {
          key: 'recurrence',
          label: 'Trocar recorrência',
          onPress: () => actionsItem && toggleRecurrence(actionsItem),
        },
        { key: 'remove', label: 'Remover item', danger: true, onPress: () => editor.setQuantity(actionsFor.handle, 0) },
      ]
    : [];

  return (
    <Screen header={header} footer={footer} onRefresh={onRefresh} refreshing={refreshing}>
      <View style={styles.heading}>
        <SectionHeader icon="options-outline" title="Minha caixa" subtitle={editable ? `Edite até o dia ${formatShortDate(editUntilIso(sub, { canEdit }), true)}` : 'Edição indisponível no momento'} />
        <Pressable onPress={() => editable && setPlanSheet(true)} disabled={!editable} accessibilityRole="button" style={styles.planChip}>
          <Badge label={editable ? 'Edição disponível' : 'Edição indisponível'} tone={editable ? 'editAvailable' : 'editUnavailable'} />
          <Text variant="caption" tone="secondary">
            {currentPlan?.name ?? sub.planName} · {frequencyLabel[editor.state.frequency]} · {currentPlan?.discountPercentage ?? sub.discount.percentage}% OFF{editable ? ' · trocar' : ''}
          </Text>
        </Pressable>
      </View>

      {!editable ? (
        <AlertCard variant="why_cant_edit" title="Por que não consigo editar minha caixa agora?" note={canEdit.until ? `Você poderá editar sua próxima caixa a partir de ${formatShortDate(canEdit.until)}.` : undefined}>
          <Text variant="body" tone="secondary">
            {canEdit.reason === 'EDIT_WINDOW_CLOSED'
              ? 'Para garantir o processamento do seu pedido, as edições da caixa ficam bloqueadas 3 dias antes da próxima cobrança.'
              : capabilityReasonLabel(canEdit.reason, canEdit.until)}
          </Text>
          {canEdit.reason === 'EDIT_WINDOW_CLOSED' ? (
            <Text variant="body" tone="secondary">
              Como sua cobrança está agendada para {formatShortDate(sub.nextBillingAt)}, não é possível editar sabor, quantidade, tamanho ou itens neste momento. Após a cobrança, as funções de edição ficarão disponíveis novamente.
            </Text>
          ) : null}
          {canEdit.reason === 'PENDING_BILL' ? <Button title="Ver fatura" size="sm" variant="secondary" onPress={() => router.navigate('/(tabs)/orders')} /> : null}
        </AlertCard>
      ) : null}

      {sub.scheduledChange ? (
        <AlertCard variant="scheduled" title="Alteração de caixa agendada!">
          <Text variant="body" tone="secondary">
            Já existe uma mudança agendada para <Text variant="bodyStrong">{formatShortDate(sub.scheduledChange.appliesAt)}</Text>. Confirmar uma nova substitui a anterior.
          </Text>
        </AlertCard>
      ) : null}

      <Text variant="bodyStrong" tone="secondary" style={styles.sectionTitle}>
        Itens da sua caixa · {editor.totalUnits} {editor.totalUnits === 1 ? 'item' : 'itens'}
      </Text>
      {inBox.length === 0 ? (
        <Card>
          <Text variant="small" tone="secondary">
            Sua caixa está vazia. Adicione pelo menos um produto.
          </Text>
        </Card>
      ) : null}
      {inBox.map((product) => {
        const item = byHandle.get(product.handle)!;
        const flavor = product.flavors?.find((f) => f.handle === item.handle);
        const price = unitPrice(item, product);
        return (
          <BoxItemRow
            key={product.handle}
            title={product.title}
            flavor={flavor?.title ?? (product.flavors?.length ? 'Escolher sabor' : undefined)}
            spec={product.category}
            imageUrl={product.imageUrl}
            recurrenceLabel={item.recurrence === null ? 'Vem em todo ciclo' : item.recurrence === 'off' ? 'Recorrência de 60 dias · pula o próximo' : 'Recorrência de 60 dias'}
            priceLabel={`${formatMoney(price.final)}/un`}
            fullPriceLabel={price.pct > 0 ? formatMoney(price.full) : undefined}
            onEdit={() => setActionsFor(product)}
            disabled={!editable}
            control={<Stepper value={item.quantity} onChange={(q) => editor.setQuantity(product.handle, q)} min={0} max={product.maxQuantity} disabled={!editable} size="sm" />}
          />
        );
      })}
      {nextTier ? (
        <Text variant="caption" tone="gold" style={styles.tierHint}>
          Adicione mais {nextTier.minItems - editor.totalUnits} {nextTier.minItems - editor.totalUnits === 1 ? 'item' : 'itens'} e ganhe {nextTier.discountPercentage}% ({nextTier.label}).
        </Text>
      ) : null}

      {available.length > 0 ? (
        <View style={styles.addSection}>
          <Text variant="bodyStrong" tone="secondary" style={styles.sectionTitle}>
            Adicionar à caixa
          </Text>
          <CategoryTabs tabs={[{ key: ALL, label: 'Todos' }, ...categories.map((c) => ({ key: c, label: c }))]} value={category} onChange={setCategory} />
          <View style={styles.grid}>
            {filteredAvailable.map((product) => {
              const final = product.price.amount * (1 - pct / 100);
              return (
                <ProductTile
                  key={product.handle}
                  title={product.title}
                  flavor={product.flavors?.[0]?.title ?? product.category}
                  imageUrl={product.imageUrl}
                  priceLabel={formatMoney(pct > 0 ? final : product.price)}
                  fullPriceLabel={pct > 0 ? formatMoney(product.price) : undefined}
                  discountPercentage={pct > 0 ? pct : undefined}
                  exclusive
                  outOfStock={!product.inStock || !editable}
                  onAdd={() => editor.setQuantity(product.handle, Math.max(1, product.minQuantity), product)}
                  width={TILE_WIDTH}
                />
              );
            })}
          </View>
        </View>
      ) : null}

      {gifts.length > 0 ? (
        <>
          <Text variant="bodyStrong" tone="secondary" style={styles.sectionTitle}>
            Seus brindes da próxima caixa
          </Text>
          <Card padded={false}>
            {gifts.map((g, idx) => {
              const selected = editor.state.giftHandles.includes(g.handle);
              return (
                <Pressable
                  key={g.handle}
                  onPress={() => editable && editor.toggleGift(g.handle)}
                  disabled={!editable}
                  accessibilityRole="checkbox"
                  accessibilityState={{ checked: selected }}
                  style={[styles.giftRow, idx < gifts.length - 1 && styles.giftBorder]}
                >
                  <ProductImage uri={g.imageUrl} title={g.title} size={48} bg={colors.subtle} />
                  <Text variant="body" style={styles.flex1}>
                    {g.title}
                  </Text>
                  <View style={[styles.check, selected && styles.checkOn]}>{selected ? <Ionicons name="checkmark" size={14} color={colors.brandDark} /> : null}</View>
                </Pressable>
              );
            })}
          </Card>
        </>
      ) : null}

      <Pressable onPress={() => setShowOptions((v) => !v)} accessibilityRole="button" accessibilityState={{ expanded: showOptions }} style={styles.optionsToggle}>
        <Text variant="bodyStrong" tone="secondary">
          Opções avançadas
        </Text>
        <Ionicons name={showOptions ? 'chevron-up' : 'chevron-down'} size={18} color={colors.text} />
      </Pressable>
      {showOptions ? (
        <>
          <Card>
            <View style={styles.row}>
              <View style={styles.flex1}>
                <Text variant="body">Aplicar só no próximo ciclo</Text>
                <Text variant="caption" tone="dim">
                  Depois, a caixa volta ao que é hoje.
                </Text>
              </View>
              <Switch
                value={editor.state.nextCycleOnly}
                onValueChange={editor.setNextCycleOnly}
                disabled={!editable}
                trackColor={{ true: colors.primaryStrong, false: colors.borderStrong }}
                thumbColor={editor.state.nextCycleOnly ? colors.gold : colors.surface}
              />
            </View>
          </Card>
          <Card title="Cupom" subtitle={sub.discount.code ? `Ativo: ${sub.discount.code} (${sub.discount.percentage}%)` : 'Tem um código? Aplique aqui.'}>
            <Input placeholder="CÓDIGO" value={coupon} onChangeText={(t) => setCoupon(t.toUpperCase())} autoCapitalize="characters" autoCorrect={false} onSubmitEditing={submitCoupon} returnKeyType="done" editable={editable} />
            <Button title="Aplicar cupom" variant="secondary" size="sm" onPress={submitCoupon} loading={applyDiscount.isPending} disabled={!editable || !coupon.trim()} />
          </Card>
        </>
      ) : null}

      <ItemActionSheet visible={actionsFor !== null} onClose={() => setActionsFor(null)} actions={itemActions} />

      <Sheet visible={planSheet} onClose={() => setPlanSheet(false)} title="Trocar plano">
        {catalog.plans.map((plan) => (
          <RadioRow
            key={plan.frequency}
            boxed
            selected={plan.frequency === editor.state.frequency}
            onPress={() => {
              editor.setFrequency(plan.frequency);
              setPlanSheet(false);
            }}
            label={plan.name}
            hint={`${frequencyLabel[plan.frequency]} · ${plan.discountPercentage}% off · ${plan.commitmentMonths > 0 ? `fidelidade ${plan.commitmentMonths} meses` : 'sem fidelidade'} · ${plan.pauseCredits} pausa${plan.pauseCredits === 1 ? '' : 's'}`}
            right={plan.highlight ? <Badge label={plan.highlight} tone="exclusive" size="sm" /> : undefined}
          />
        ))}
      </Sheet>

      <Sheet visible={flavorFor !== null} onClose={() => setFlavorFor(null)} title={flavorFor ? `Sabor · ${flavorFor.title}` : 'Sabor'}>
        {flavorFor?.flavors?.map((f) => (
          <RadioRow
            key={f.handle}
            boxed
            disabled={!f.inStock}
            selected={byHandle.get(flavorFor.handle)?.handle === f.handle}
            onPress={() => {
              editor.setFlavor(flavorFor.handle, f.handle);
              setFlavorFor(null);
            }}
            label={f.title}
            hint={!f.inStock ? 'Esgotado' : undefined}
          />
        ))}
      </Sheet>
    </Screen>
  );
}

const TILE_WIDTH = 150;

const styles = StyleSheet.create({
  flex1: { flex: 1 },
  row: { flexDirection: 'row', alignItems: 'center', gap: space(3) },
  heading: { marginBottom: space(2) },
  planChip: { flexDirection: 'row', alignItems: 'center', gap: space(2), flexWrap: 'wrap', marginTop: -space(1), marginBottom: space(2) },
  sectionTitle: { marginBottom: space(2), marginTop: space(2) },
  tierHint: { marginTop: space(1), marginBottom: space(2) },
  addSection: { marginTop: space(2) },
  grid: { flexDirection: 'row', flexWrap: 'wrap', gap: space(3), justifyContent: 'space-between' },
  giftRow: { flexDirection: 'row', alignItems: 'center', gap: space(3), padding: space(3) },
  giftBorder: { borderBottomWidth: 1, borderBottomColor: colors.border },
  check: { width: 22, height: 22, borderRadius: radius.xs, borderWidth: 1.5, borderColor: colors.borderStrong, alignItems: 'center', justifyContent: 'center' },
  checkOn: { backgroundColor: colors.primary, borderColor: colors.primary },
  optionsToggle: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingVertical: space(3) },
  warnings: { gap: 2 },
});
