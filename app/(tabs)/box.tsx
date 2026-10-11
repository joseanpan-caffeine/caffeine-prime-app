import { useMemo, useState } from 'react';
import { Pressable, StyleSheet, Switch, View } from 'react-native';
import { useRouter } from 'expo-router';
import { Image } from 'expo-image';
import type { Catalog, CatalogProduct, ItemRecurrence, Subscription } from '@/api/contracts';
import { errorMessage } from '@/api/client';
import { useApplyDiscount, useCatalog, useDashboard, usePreview, useScheduleChange, useSetItemRecurrence, useSubscription } from '@/api/hooks';
import { Badge, Button, Card, EmptyState, Input, Money, Row, Screen, Section, Sheet, SkeletonCard, Stepper, Text, toast } from '@/components';
import { type EditorItem, useBoxEditor } from '@/features/box/useBoxEditor';
import { formatDate } from '@/lib/format';
import { capabilityReasonLabel, frequencyLabel } from '@/lib/labels';
import { colors, radius, space } from '@/theme';

export default function BoxScreen() {
  const dashboard = useDashboard();
  const subscription = useSubscription();
  const catalog = useCatalog();

  const loading = dashboard.isLoading || subscription.isLoading || catalog.isLoading;
  const refetch = () => {
    void dashboard.refetch();
    void subscription.refetch();
    void catalog.refetch();
  };

  if (loading) {
    return (
      <Screen safeTop title="Minha caixa">
        <SkeletonCard lines={2} />
        <SkeletonCard lines={4} />
      </Screen>
    );
  }

  const sub = subscription.data ?? dashboard.data?.subscription ?? null;
  if (!sub || !catalog.data || !dashboard.data) {
    return (
      <Screen safeTop title="Minha caixa" onRefresh={refetch} refreshing={subscription.isRefetching}>
        <EmptyState title="Caixa indisponível" description={errorMessage(subscription.error ?? catalog.error ?? dashboard.error, 'Não há assinatura para editar.')} actionLabel="Tentar de novo" onAction={refetch} />
      </Screen>
    );
  }

  return <BoxEditor sub={sub} catalog={catalog.data} canEdit={dashboard.data.capabilities.canEdit} onRefresh={refetch} refreshing={subscription.isRefetching} />;
}

interface EditorProps {
  sub: Subscription;
  catalog: Catalog;
  canEdit: { allowed: boolean; reason?: Parameters<typeof capabilityReasonLabel>[0]; until?: string };
  onRefresh: () => void;
  refreshing: boolean;
}

function BoxEditor({ sub, catalog, canEdit, onRefresh, refreshing }: EditorProps) {
  const router = useRouter();
  const editor = useBoxEditor(sub, catalog);
  const preview = usePreview(editor.previewRequest);
  const schedule = useScheduleChange();
  const setRecurrenceRemote = useSetItemRecurrence();
  const applyDiscount = useApplyDiscount();
  const [planSheet, setPlanSheet] = useState(false);
  const [flavorFor, setFlavorFor] = useState<CatalogProduct | null>(null);
  const [coupon, setCoupon] = useState('');

  const editable = canEdit.allowed;
  const byHandle = useMemo(() => new Map(editor.state.items.map((i) => [i.productHandle, i])), [editor.state.items]);
  const inBox = catalog.products.filter((p) => (byHandle.get(p.handle)?.quantity ?? 0) > 0);
  const available = catalog.products.filter((p) => (byHandle.get(p.handle)?.quantity ?? 0) === 0);
  const gifts = catalog.gifts.filter((g) => !g.requiresPlan || g.requiresPlan.includes(editor.state.frequency));
  const nextTier = [...catalog.discountTiers].sort((a, b) => a.minItems - b.minItems).find((t) => t.minItems > editor.totalUnits);
  const currentPlan = catalog.plans.find((p) => p.frequency === editor.state.frequency);

  function unitPrice(item: EditorItem, product: CatalogProduct) {
    const p = preview.data?.items.find((i) => i.handle === item.handle);
    return p ? { final: p.finalUnitPrice, full: p.unitPrice, pct: p.discountPercentage } : { final: product.price, full: product.price, pct: 0 };
  }

  function toggleRecurrence(item: EditorItem, on: boolean) {
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
  const pct = preview.data?.appliedDiscountPercentage ?? sub.discount.percentage;
  const canConfirm = editable && editor.dirty && !!editor.schedulingRequest && !preview.isError && !preview.isFetching;

  const footer = (
    <View>
      {preview.data?.warnings.map((w) => (
        <Text key={w} variant="caption" tone="accent" style={styles.warning}>
          {w}
        </Text>
      ))}
      {preview.isError ? (
        <Text variant="caption" tone="danger" style={styles.warning}>
          {errorMessage(preview.error, 'Não foi possível calcular o preço.')}
        </Text>
      ) : null}
      <Row>
        <View>
          <Text variant="caption" tone="muted">
            {editor.dirty ? 'NOVO TOTAL POR CICLO' : 'TOTAL POR CICLO'}
            {preview.isFetching ? ' · calculando…' : ''}
          </Text>
          <Row style={styles.totalRow}>
            <Money value={total} variant="title" tone="accent" />
            {subtotal.amount > total.amount ? <Money value={subtotal} variant="small" tone="dim" strike /> : null}
            {pct > 0 ? <Badge label={`-${pct}%`} tone="success" /> : null}
          </Row>
        </View>
        <View style={styles.footerActions}>
          {editor.dirty ? <Button title="Descartar" variant="ghost" size="sm" full={false} onPress={editor.reset} /> : null}
          <Button title="Confirmar" size="sm" full={false} onPress={confirm} disabled={!canConfirm} loading={schedule.isPending} />
        </View>
      </Row>
    </View>
  );

  return (
    <Screen safeTop footer={footer} onRefresh={onRefresh} refreshing={refreshing}>
      <Row style={styles.heading}>
        <Text variant="title">Minha caixa</Text>
        <Pressable onPress={() => editable && setPlanSheet(true)} disabled={!editable} accessibilityRole="button">
          <Badge label={`${frequencyLabel[editor.state.frequency]} · trocar`} tone="accent" />
        </Pressable>
      </Row>
      <Text variant="small" tone="muted" style={styles.planLine}>
        {currentPlan?.name ?? sub.planName} · {currentPlan?.discountPercentage ?? sub.discount.percentage}% de desconto
        {currentPlan?.commitmentMonths ? ` · fidelidade ${currentPlan.commitmentMonths} meses` : ''}
      </Text>

      {!editable ? (
        <Card tone="accent">
          <Text variant="bodyStrong">Edição indisponível</Text>
          <Text variant="small" tone="muted" style={styles.mt1}>
            {capabilityReasonLabel(canEdit.reason, canEdit.until)}
          </Text>
          {canEdit.reason === 'PENDING_BILL' ? (
            <Button title="Ver fatura" size="sm" variant="secondary" style={styles.mt3} onPress={() => router.navigate('/(tabs)/orders')} />
          ) : null}
        </Card>
      ) : null}

      {sub.scheduledChange ? (
        <Card tone="elevated">
          <Text variant="small" tone="muted">
            Já existe uma mudança agendada para {formatDate(sub.scheduledChange.appliesAt)}. Confirmar uma nova substitui a anterior.
          </Text>
        </Card>
      ) : null}

      <Section title={`Na sua caixa · ${editor.totalUnits} ${editor.totalUnits === 1 ? 'item' : 'itens'}`}>
        {inBox.length === 0 ? (
          <Card>
            <Text variant="small" tone="muted">
              Sua caixa está vazia. Adicione pelo menos um produto.
            </Text>
          </Card>
        ) : null}
        {inBox.map((product) => {
          const item = byHandle.get(product.handle)!;
          const flavor = product.flavors?.find((f) => f.handle === item.handle);
          const price = unitPrice(item, product);
          return (
            <Card key={product.handle} padded={false} style={styles.productCard}>
              <View style={styles.productRow}>
                <Thumb uri={product.imageUrl} />
                <View style={styles.flex1}>
                  <Text variant="bodyStrong" numberOfLines={2}>
                    {product.title}
                  </Text>
                  {product.flavors && product.flavors.length > 0 ? (
                    <Pressable onPress={() => editable && setFlavorFor(product)} disabled={!editable} accessibilityRole="button" style={styles.flavorBtn}>
                      <Text variant="caption" tone="accent">
                        {flavor?.title ?? 'Escolher sabor'} {editable ? '· trocar' : ''}
                      </Text>
                    </Pressable>
                  ) : null}
                  <Row style={styles.priceRow}>
                    <Money value={price.final} variant="small" />
                    {price.pct > 0 ? <Money value={price.full} variant="caption" tone="dim" strike /> : null}
                    <Text variant="caption" tone="dim">
                      /un
                    </Text>
                  </Row>
                </View>
                <Stepper value={item.quantity} onChange={(q) => editor.setQuantity(product.handle, q)} min={0} max={product.maxQuantity} disabled={!editable} />
              </View>
              <Row style={styles.recurrenceRow}>
                <View style={styles.flex1}>
                  <Text variant="small">A cada 60 dias</Text>
                  <Text variant="caption" tone="dim">
                    {item.recurrence === 'off' ? 'Pula o próximo ciclo' : item.recurrence === 'on' ? 'Vem no próximo ciclo' : 'Vem em todo ciclo'}
                  </Text>
                </View>
                <Switch
                  value={item.recurrence !== null}
                  onValueChange={(on) => toggleRecurrence(item, on)}
                  disabled={!editable || setRecurrenceRemote.isPending}
                  trackColor={{ true: colors.accentDark, false: colors.borderStrong }}
                  thumbColor={item.recurrence !== null ? colors.accent : colors.textMuted}
                />
              </Row>
            </Card>
          );
        })}
        {nextTier ? (
          <Text variant="caption" tone="accent" style={styles.tierHint}>
            Adicione mais {nextTier.minItems - editor.totalUnits} {nextTier.minItems - editor.totalUnits === 1 ? 'item' : 'itens'} e ganhe {nextTier.discountPercentage}% ({nextTier.label}).
          </Text>
        ) : null}
      </Section>

      {available.length > 0 ? (
        <Section title="Adicionar à caixa">
          {available.map((product) => (
            <Card key={product.handle} padded={false} style={styles.productCard}>
              <View style={styles.productRow}>
                <Thumb uri={product.imageUrl} />
                <View style={styles.flex1}>
                  <Text variant="bodyStrong" numberOfLines={2}>
                    {product.title}
                  </Text>
                  <Text variant="caption" tone="muted">
                    {product.category}
                    {!product.inStock ? ' · esgotado' : ''}
                  </Text>
                  <Money value={product.price} variant="small" />
                </View>
                <Button
                  title="Adicionar"
                  size="sm"
                  variant="secondary"
                  full={false}
                  disabled={!editable || !product.inStock}
                  onPress={() => editor.setQuantity(product.handle, Math.max(1, product.minQuantity), product)}
                />
              </View>
            </Card>
          ))}
        </Section>
      ) : null}

      {gifts.length > 0 ? (
        <Section title="Brindes">
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
                  <Thumb uri={g.imageUrl} size={40} />
                  <Text variant="small" style={styles.flex1}>
                    {g.title}
                  </Text>
                  <View style={[styles.check, selected && styles.checkOn]}>{selected ? <Text variant="caption" tone="onAccent">✓</Text> : null}</View>
                </Pressable>
              );
            })}
          </Card>
        </Section>
      ) : null}

      <Section title="Opções">
        <Card>
          <Row>
            <View style={styles.flex1}>
              <Text variant="small">Aplicar só no próximo ciclo</Text>
              <Text variant="caption" tone="dim">
                Depois, a caixa volta ao que é hoje.
              </Text>
            </View>
            <Switch
              value={editor.state.nextCycleOnly}
              onValueChange={editor.setNextCycleOnly}
              disabled={!editable}
              trackColor={{ true: colors.accentDark, false: colors.borderStrong }}
              thumbColor={editor.state.nextCycleOnly ? colors.accent : colors.textMuted}
            />
          </Row>
        </Card>
        <Card title="Cupom" subtitle={sub.discount.code ? `Ativo: ${sub.discount.code} (${sub.discount.percentage}%)` : 'Tem um código? Aplique aqui.'}>
          <Input placeholder="CÓDIGO" value={coupon} onChangeText={(t) => setCoupon(t.toUpperCase())} autoCapitalize="characters" autoCorrect={false} onSubmitEditing={submitCoupon} returnKeyType="done" editable={editable} />
          <Button title="Aplicar cupom" variant="secondary" size="sm" onPress={submitCoupon} loading={applyDiscount.isPending} disabled={!editable || !coupon.trim()} />
        </Card>
      </Section>

      <Sheet visible={planSheet} onClose={() => setPlanSheet(false)} title="Trocar plano">
        {catalog.plans.map((plan) => {
          const active = plan.frequency === editor.state.frequency;
          return (
            <Pressable
              key={plan.frequency}
              onPress={() => {
                editor.setFrequency(plan.frequency);
                setPlanSheet(false);
              }}
              accessibilityRole="radio"
              accessibilityState={{ selected: active }}
              style={[styles.planRow, active && styles.planRowActive]}
            >
              <View style={styles.flex1}>
                <Row style={styles.planTitle}>
                  <Text variant="bodyStrong">{plan.name}</Text>
                  {plan.highlight ? <Badge label={plan.highlight} tone="accent" /> : null}
                </Row>
                <Text variant="caption" tone="muted">
                  {frequencyLabel[plan.frequency]} · {plan.discountPercentage}% off · {plan.commitmentMonths > 0 ? `fidelidade ${plan.commitmentMonths} meses` : 'sem fidelidade'} ·{' '}
                  {plan.pauseCredits} pausa{plan.pauseCredits === 1 ? '' : 's'}
                </Text>
              </View>
              <View style={[styles.radio, active && styles.radioOn]} />
            </Pressable>
          );
        })}
      </Sheet>

      <Sheet visible={flavorFor !== null} onClose={() => setFlavorFor(null)} title={flavorFor ? `Sabor · ${flavorFor.title}` : 'Sabor'}>
        {flavorFor?.flavors?.map((f) => {
          const active = byHandle.get(flavorFor.handle)?.handle === f.handle;
          return (
            <Pressable
              key={f.handle}
              disabled={!f.inStock}
              onPress={() => {
                editor.setFlavor(flavorFor.handle, f.handle);
                setFlavorFor(null);
              }}
              accessibilityRole="radio"
              accessibilityState={{ selected: active, disabled: !f.inStock }}
              style={[styles.planRow, active && styles.planRowActive, !f.inStock && styles.disabled]}
            >
              <Text variant="bodyStrong" style={styles.flex1}>
                {f.title}
                {!f.inStock ? '  · esgotado' : ''}
              </Text>
              <View style={[styles.radio, active && styles.radioOn]} />
            </Pressable>
          );
        })}
      </Sheet>
    </Screen>
  );
}

function Thumb({ uri, size = 56 }: { uri?: string; size?: number }) {
  return (
    <View style={[styles.thumb, { width: size, height: size }]}>
      {uri ? <Image source={{ uri }} style={StyleSheet.absoluteFill} contentFit="cover" transition={150} /> : <Text variant="heading">☕</Text>}
    </View>
  );
}

const styles = StyleSheet.create({
  flex1: { flex: 1 },
  mt1: { marginTop: space(1) },
  mt3: { marginTop: space(3) },
  heading: { marginBottom: space(1) },
  planLine: { marginBottom: space(4) },
  productCard: { padding: space(3) },
  productRow: { flexDirection: 'row', alignItems: 'center', gap: space(3) },
  thumb: { borderRadius: radius.md, backgroundColor: colors.surfaceElevated, alignItems: 'center', justifyContent: 'center', overflow: 'hidden' },
  flavorBtn: { alignSelf: 'flex-start', marginTop: 2 },
  priceRow: { justifyContent: 'flex-start', gap: space(1.5), marginTop: 2 },
  recurrenceRow: { marginTop: space(3), paddingTop: space(3), borderTopWidth: StyleSheet.hairlineWidth, borderTopColor: colors.border },
  tierHint: { marginTop: space(1) },
  giftRow: { flexDirection: 'row', alignItems: 'center', gap: space(3), padding: space(3) },
  giftBorder: { borderBottomWidth: StyleSheet.hairlineWidth, borderBottomColor: colors.border },
  check: { width: 24, height: 24, borderRadius: 6, borderWidth: 1.5, borderColor: colors.borderStrong, alignItems: 'center', justifyContent: 'center' },
  checkOn: { backgroundColor: colors.accent, borderColor: colors.accent },
  planRow: { flexDirection: 'row', alignItems: 'center', gap: space(3), padding: space(3), borderRadius: radius.md, borderWidth: 1, borderColor: colors.border, marginBottom: space(2) },
  planRowActive: { borderColor: colors.accent, backgroundColor: colors.accentSoft },
  planTitle: { justifyContent: 'flex-start' },
  radio: { width: 20, height: 20, borderRadius: 10, borderWidth: 2, borderColor: colors.borderStrong },
  radioOn: { borderColor: colors.accent, backgroundColor: colors.accent },
  disabled: { opacity: 0.5 },
  warning: { marginBottom: space(2) },
  totalRow: { justifyContent: 'flex-start', gap: space(2) },
  footerActions: { flexDirection: 'row', alignItems: 'center', gap: space(1) },
});
