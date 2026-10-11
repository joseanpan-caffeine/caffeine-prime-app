import { Linking, StyleSheet, View } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import * as Clipboard from 'expo-clipboard';
import type { Fulfillment } from '@/api/contracts';
import { errorMessage } from '@/api/client';
import { useBill } from '@/api/hooks';
import { Badge, Button, Card, EmptyState, Money, Row, Screen, Section, SkeletonCard, Text, toast } from '@/components';
import { billTone } from '@/features/orders/BillCard';
import { formatDate, formatDateTime } from '@/lib/format';
import { billStatusLabel, fulfillmentLabel, paymentMethodLabel } from '@/lib/labels';
import { colors, space } from '@/theme';

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

  const units = bill.items.reduce((n, i) => n + i.quantity, 0);

  return (
    <Screen onRefresh={refetch} refreshing={isRefetching}>
      <Card right={<Badge label={billStatusLabel[bill.status]} tone={billTone[bill.status]} />} title={`Ciclo ${bill.cycle}`} subtitle={`Emitida em ${formatDate(bill.issuedAt)}`}>
        <Row>
          <Text variant="small" tone="muted">
            Total
          </Text>
          <Money value={bill.amount} variant="title" tone="accent" />
        </Row>
        {bill.status === 'pending' ? (
          <>
            <Text variant="small" tone="muted" style={styles.mt2}>
              Vence em {formatDate(bill.dueAt)}. Após o vencimento do PIX a cobrança vai para o cartão.
            </Text>
            <Button title="Pagar agora" style={styles.mt3} onPress={() => router.push({ pathname: '/payments/pay/[billId]', params: { billId: bill.id } })} />
          </>
        ) : null}
      </Card>

      <Section title={`Itens · ${units}`}>
        <Card padded={false}>
          {bill.items.map((item, idx) => (
            <Row key={item.id} style={[styles.itemRow, idx < bill.items.length - 1 && styles.itemBorder]}>
              <View style={styles.flex1}>
                <Text variant="bodyStrong" numberOfLines={2}>
                  {item.quantity}× {item.title}
                </Text>
                {item.flavor || item.isGift ? (
                  <Text variant="caption" tone="muted">
                    {[item.flavor, item.isGift ? 'brinde' : null].filter(Boolean).join(' · ')}
                  </Text>
                ) : null}
              </View>
              <Money value={item.isGift ? 0 : item.finalPrice.amount * item.quantity} variant="small" />
            </Row>
          ))}
        </Card>
      </Section>

      <Section title="Pagamento">
        <Card>
          <Row>
            <Text variant="small" tone="muted">
              Método
            </Text>
            <Text variant="bodyStrong">{paymentMethodLabel(bill)}</Text>
          </Row>
          {bill.paidAt ? (
            <Row style={styles.mt2}>
              <Text variant="small" tone="muted">
                Pago em
              </Text>
              <Text variant="small">{formatDateTime(bill.paidAt)}</Text>
            </Row>
          ) : null}
          <Row style={styles.mt2}>
            <Text variant="small" tone="muted">
              Vencimento
            </Text>
            <Text variant="small">{formatDate(bill.dueAt)}</Text>
          </Row>
        </Card>
      </Section>

      {bill.fulfillment ? <Tracking fulfillment={bill.fulfillment} /> : null}
    </Screen>
  );
}

function Tracking({ fulfillment }: { fulfillment: Fulfillment }) {
  const tone = fulfillment.status === 'delivered' ? 'success' : fulfillment.status === 'failed' ? 'danger' : 'info';
  async function copyCode() {
    if (!fulfillment.trackingCode) return;
    await Clipboard.setStringAsync(fulfillment.trackingCode);
    toast.success('Código de rastreio copiado.');
  }
  return (
    <Section title="Rastreio">
      <Card right={<Badge label={fulfillmentLabel[fulfillment.status]} tone={tone} />} title={fulfillment.carrier ?? 'Transportadora'} subtitle={fulfillment.estimatedDeliveryAt ? `Previsão: ${formatDate(fulfillment.estimatedDeliveryAt)}` : undefined}>
        {fulfillment.trackingCode ? (
          <Row>
            <Text variant="mono" tone="muted">
              {fulfillment.trackingCode}
            </Text>
            <Button title="Copiar" variant="ghost" size="sm" full={false} onPress={copyCode} />
          </Row>
        ) : null}
        {fulfillment.trackingUrl ? (
          <Button title="Abrir no site da transportadora" variant="secondary" size="sm" style={styles.mt2} onPress={() => Linking.openURL(fulfillment.trackingUrl!).catch(() => toast.error('Não foi possível abrir.'))} />
        ) : null}
        <View style={styles.timeline}>
          {fulfillment.events.length === 0 ? (
            <Text variant="small" tone="muted">
              Ainda sem eventos de rastreio.
            </Text>
          ) : null}
          {fulfillment.events.map((ev, idx) => (
            <View key={`${ev.occurredAt}-${idx}`} style={styles.event}>
              <View style={styles.rail}>
                <View style={[styles.dot, idx === 0 && styles.dotActive]} />
                {idx < fulfillment.events.length - 1 ? <View style={styles.line} /> : null}
              </View>
              <View style={styles.eventBody}>
                <Text variant={idx === 0 ? 'bodyStrong' : 'small'}>{ev.description}</Text>
                <Text variant="caption" tone="dim">
                  {formatDateTime(ev.occurredAt)}
                  {ev.location ? ` · ${ev.location}` : ''}
                </Text>
              </View>
            </View>
          ))}
        </View>
      </Card>
    </Section>
  );
}

const styles = StyleSheet.create({
  flex1: { flex: 1 },
  mt2: { marginTop: space(2) },
  mt3: { marginTop: space(3) },
  itemRow: { padding: space(3) },
  itemBorder: { borderBottomWidth: StyleSheet.hairlineWidth, borderBottomColor: colors.border },
  timeline: { marginTop: space(3) },
  event: { flexDirection: 'row', gap: space(3) },
  rail: { alignItems: 'center', width: 12 },
  dot: { width: 10, height: 10, borderRadius: 5, backgroundColor: colors.borderStrong, marginTop: 6 },
  dotActive: { backgroundColor: colors.accent },
  line: { flex: 1, width: 2, backgroundColor: colors.border, marginVertical: 2 },
  eventBody: { flex: 1, paddingBottom: space(4), gap: 2 },
});
