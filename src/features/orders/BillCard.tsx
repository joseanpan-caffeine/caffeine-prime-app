import { Pressable, StyleSheet, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import type { Bill, BillStatus, Fulfillment } from '@/api/contracts';
import { Badge, Money, ProductImage, Text } from '@/components';
import type { BadgeTone } from '@/components/Badge';
import { fulfillmentLabel, isPausedCycleBill } from '@/lib/labels';
import { formatShortDate } from '@/lib/prime';
import { colors, radius, shadows, space } from '@/theme';

export const billTone: Record<BillStatus, BadgeTone> = { pending: 'pending', paid: 'active', canceled: 'canceled', review: 'review' };

/** Cor do ponto de status (Figma Pedido): amarelo em andamento, vermelho cancelado, verde entregue. */
export function orderStatusDot(bill: Bill): { color: string; label: string } {
  // Fatura R$ 0,00 de ciclo pausado: não há pedido nem envio; é o comportamento esperado da pausa.
  if (isPausedCycleBill(bill)) return { color: colors.textMuted, label: 'Sem envio neste ciclo' };
  if (bill.status === 'canceled') return { color: colors.danger, label: 'Cancelado' };
  if (bill.status === 'pending') return { color: colors.warning, label: 'Aguardando pagamento' };
  if (bill.status === 'review') return { color: colors.warning, label: 'Pagamento em análise' };
  const f: Fulfillment['status'] | undefined = bill.fulfillment?.status;
  if (f === 'delivered') return { color: colors.success, label: 'Entregue' };
  if (f === 'failed') return { color: colors.danger, label: fulfillmentLabel.failed };
  if (f === 'processing') return { color: colors.warning, label: 'Em separação' };
  if (f === 'pending' || !f) return { color: colors.warning, label: 'Pronto para envio' };
  return { color: colors.warning, label: fulfillmentLabel[f] };
}

/** Card de pedido (Figma Pedido): thumb com contador, badge ASSINATURA, "Pedido #id", ponto de status, data de criação, chevron. */
export function BillCard({ bill, onPress }: { bill: Bill; onPress: () => void }) {
  const units = bill.items.reduce((n, i) => n + i.quantity, 0);
  const first = bill.items[0];
  const dot = orderStatusDot(bill);
  const paused = isPausedCycleBill(bill);
  return (
    <Pressable onPress={onPress} accessibilityRole="button" style={({ pressed }) => [styles.card, shadows.card, pressed && styles.pressed]}>
      <View style={styles.thumbWrap}>
        <ProductImage uri={first?.imageUrl} handle={first?.handle} title={first?.title ?? 'Pedido'} size={64} bg={colors.subtle} />
        {units > 1 ? (
          <View style={styles.count}>
            <Text variant="captionStrong" tone="secondary">
              {units}
            </Text>
          </View>
        ) : null}
      </View>
      <View style={styles.body}>
        <View style={styles.badges}>
          <Badge label="Assinatura" tone="orderSubscription" size="sm" />
          {paused ? <Badge label="Ciclo pausado" tone="paused" size="sm" /> : null}
        </View>
        <Text variant="bodyStrong" numberOfLines={1}>
          {paused ? `Ciclo ${bill.cycle} pausado` : `Pedido #${bill.id}`}
        </Text>
        <View style={styles.statusRow}>
          <View style={[styles.dot, { backgroundColor: dot.color }]} />
          <Text variant="small" tone="secondary" numberOfLines={1}>
            {dot.label}
          </Text>
        </View>
        <Text variant="small" tone="secondary">
          Data de criação: {formatShortDate(bill.issuedAt, true)}
        </Text>
        <Money value={bill.amount} variant="smallStrong" />
      </View>
      <Ionicons name="chevron-forward" size={18} color={colors.text} />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: { flexDirection: 'row', alignItems: 'center', gap: space(3), backgroundColor: colors.surface, borderRadius: radius.md, padding: space(3), marginBottom: space(3) },
  pressed: { opacity: 0.85 },
  thumbWrap: { position: 'relative' },
  count: { position: 'absolute', right: -6, bottom: -6, width: 22, height: 22, borderRadius: 11, backgroundColor: colors.muted, borderWidth: 2, borderColor: colors.surface, alignItems: 'center', justifyContent: 'center' },
  body: { flex: 1, gap: 3 },
  badges: { flexDirection: 'row', gap: space(1), flexWrap: 'wrap' },
  statusRow: { flexDirection: 'row', alignItems: 'center', gap: space(1.5) },
  dot: { width: 8, height: 8, borderRadius: 4 },
});
