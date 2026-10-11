import { Linking, StyleSheet, View } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import * as Clipboard from 'expo-clipboard';
import type { Fulfillment } from '@/api/contracts';
import { errorMessage } from '@/api/client';
import { useBill } from '@/api/hooks';
import { Badge, Button, Card, EmptyState, Money, ProductImage, Row, Screen, SkeletonCard, Text, toast } from '@/components';
import { billTone, orderStatusDot } from '@/features/orders/BillCard';
import { formatDate, formatDateTime } from '@/lib/format';
import { billStatusLabel, fulfillmentLabel, paymentMethodLabel } from '@/lib/labels';
import { formatShortDate } from '@/lib/prime';
import { colors, radius, space } from '@/theme';

export default function OrderDetail() {
  const { billId } = useLocalSearchParams<{ billId: string }>();
  const router = useRouter();
  const { data: bill, isLoading, isError, error, refetch, isRefetching } = useBill(billId);

  if (isLoading) {
    return (
      <Screen>
        <SkeletonCard lines={3} />
        <SkeletonCard lines={4} />
      </Screen>
    );
  }
  if (isError || !bill) {
    return (
      <Screen>
        <EmptyState icon="⚠️" title="Pedido não encontrado" description={errorMessage(error)} actionLabel="Tentar de novo" onAction={() => refetch()} />
      </Screen>
    );
  }

  const dot = orderStatusDot(bill);

  return (
    <Screen onRefresh={refetch} refreshing={isRefetching}>
      <Card>
        <View style={styles.head}>
          <View style={styles.flex1}>
            <Badge label="Assinatura" tone="orderSubscription" size="sm" />
            <Text variant="heading" style={styles.mt1}>
              Pedido #{bill.id}
            </Text>
            <View style={styles.statusRow}>
              <View style={[styles.dot, { backgroundColor: dot.color }]} />
              <Text variant="small" tone="secondary">
                {dot.label}
              </Text>
            </View>
            <Text variant="small" tone="secondary">
              Data de criação: {formatShortDate(bill.issuedAt, true)} · Ciclo {bill.cycle}
            </Text>
          </View>
          <Badge label={billStatusLabel[bill.status]} tone={billTone[bill.status]} />
        </View>
        <Row style={styles.totalRow}>
          <Text variant="body" tone="secondary">
            Total
          </Text>
          <Money value={bill.amount} variant="heading" />
        </Row>
        {bill.status === 'pending' ? (
          <>
            <Text variant="small" tone="secondary" style={styles.mt2}>
              Vence em {formatDate(bill.dueAt)}. Após o vencimento do PIX a cobrança vai para o cartão.
            </Text>
            <Button title="Regularizar pagamento" style={styles.mt3} onPress={() => router.push({ pathname: '/payments/pay/[billId]', params: { billId: bill.id } })} />
          </>
        ) : null}
      </Card>

      <Text variant="bodyStrong" tone="secondary" style={styles.sectionTitle}>
        Itens do pedido
      </Text>
      <Card padded={false}>
        {bill.items.map((item, idx) => (
          <View key={item.id} style={[styles.itemRow, idx < bill.items.length - 1 && styles.itemBorder]}>
            <ProductImage uri={item.imageUrl} title={item.title} size={56} bg={colors.subtle} />
            <View style={styles.flex1}>
              <Text variant="bodyStrong" numberOfLines={2}>
                {item.title}
              </Text>
              <Text variant="small" tone="secondary" numberOfLines={1}>
                {[item.flavor, item.isGift ? 'Brinde' : null, `${item.quantity} un.`].filter(Boolean).join(' · ')}
              </Text>
            </View>
            <Money value={item.isGift ? 0 : item.finalPrice.amount * item.quantity} variant="bodyStrong" />
          </View>
        ))}
      </Card>

      <Text variant="bodyStrong" tone="secondary" style={styles.sectionTitle}>
        Pagamento
      </Text>
      <Card>
        <Row>
          <Text variant="small" tone="secondary">
            Método
          </Text>
          <Text variant="bodyStrong">{paymentMethodLabel(bill)}</Text>
        </Row>
        {bill.paidAt ? (
          <Row style={styles.mt2}>
            <Text variant="small" tone="secondary">
              Pago em
            </Text>
            <Text variant="small">{formatDateTime(bill.paidAt)}</Text>
          </Row>
        ) : null}
        <Row style={styles.mt2}>
          <Text variant="small" tone="secondary">
            Vencimento
          </Text>
          <Text variant="small">{formatDate(bill.dueAt)}</Text>
        </Row>
      </Card>

      {bill.fulfillment ? <Tracking fulfillment={bill.fulfillment} /> : null}
    </Screen>
  );
}

function Tracking({ fulfillment }: { fulfillment: Fulfillment }) {
  const tone = fulfillment.status === 'delivered' ? 'active' : fulfillment.status === 'failed' ? 'pending' : 'scheduled';
  async function copyCode() {
    if (!fulfillment.trackingCode) return;
    await Clipboard.setStringAsync(fulfillment.trackingCode);
    toast.success('Código de rastreio copiado.');
  }
  return (
    <>
      <Text variant="bodyStrong" tone="secondary" style={styles.sectionTitle}>
        Rastreio
      </Text>
      <Card right={<Badge label={fulfillmentLabel[fulfillment.status]} tone={tone} />} title={fulfillment.carrier ?? 'Transportadora'} subtitle={fulfillment.estimatedDeliveryAt ? `Previsão: ${formatDate(fulfillment.estimatedDeliveryAt)}` : undefined}>
        {fulfillment.trackingCode ? (
          <Row>
            <Text variant="mono" tone="secondary">
              {fulfillment.trackingCode}
            </Text>
            <Button title="Copiar" variant="ghost" size="sm" full={false} onPress={copyCode} icon={<Ionicons name="copy-outline" size={14} color={colors.text} />} />
          </Row>
        ) : null}
        {fulfillment.trackingUrl ? (
          <Button
            title="Rastrear pedido"
            variant="secondary"
            size="sm"
            style={styles.mt2}
            icon={<Ionicons name="open-outline" size={14} color={colors.text} />}
            onPress={() => Linking.openURL(fulfillment.trackingUrl!).catch(() => toast.error('Não foi possível abrir.'))}
          />
        ) : null}
        <View style={styles.timeline}>
          {fulfillment.events.length === 0 ? (
            <Text variant="small" tone="secondary">
              Ainda sem eventos de rastreio.
            </Text>
          ) : null}
          {fulfillment.events.map((ev, idx) => (
            <View key={`${ev.occurredAt}-${idx}`} style={styles.event}>
              <View style={styles.rail}>
                <View style={[styles.eventDot, idx === 0 && styles.eventDotActive]}>{idx === 0 ? <Ionicons name="checkmark" size={10} color="#FFFFFF" /> : null}</View>
                {idx < fulfillment.events.length - 1 ? <View style={styles.line} /> : null}
              </View>
              <View style={styles.eventBody}>
                <Text variant={idx === 0 ? 'bodyStrong' : 'body'}>{ev.description}</Text>
                <Text variant="caption" tone="dim">
                  {formatDateTime(ev.occurredAt)}
                  {ev.location ? ` · ${ev.location}` : ''}
                </Text>
              </View>
            </View>
          ))}
        </View>
      </Card>
    </>
  );
}

const styles = StyleSheet.create({
  flex1: { flex: 1 },
  mt1: { marginTop: space(1) },
  mt2: { marginTop: space(2) },
  mt3: { marginTop: space(3) },
  head: { flexDirection: 'row', alignItems: 'flex-start', gap: space(2) },
  statusRow: { flexDirection: 'row', alignItems: 'center', gap: space(1.5), marginTop: 2 },
  dot: { width: 8, height: 8, borderRadius: 4 },
  totalRow: { marginTop: space(3), paddingTop: space(3), borderTopWidth: 1, borderTopColor: colors.border },
  sectionTitle: { marginBottom: space(2) },
  itemRow: { flexDirection: 'row', alignItems: 'center', gap: space(3), padding: space(3) },
  itemBorder: { borderBottomWidth: 1, borderBottomColor: colors.border },
  timeline: { marginTop: space(3) },
  event: { flexDirection: 'row', gap: space(3) },
  rail: { alignItems: 'center', width: 16 },
  eventDot: { width: 16, height: 16, borderRadius: radius.pill, backgroundColor: colors.borderStrong, marginTop: 2, alignItems: 'center', justifyContent: 'center' },
  eventDotActive: { backgroundColor: colors.success },
  line: { flex: 1, width: 2, backgroundColor: colors.border, marginVertical: 2 },
  eventBody: { flex: 1, paddingBottom: space(4), gap: 2 },
});
