import { View, StyleSheet } from 'react-native';
import type { Bill, BillStatus } from '@/api/contracts';
import { Badge, Card, Money, Row, Text } from '@/components';
import type { BadgeTone } from '@/components/Badge';
import { formatDate } from '@/lib/format';
import { billStatusLabel, fulfillmentLabel, paymentMethodLabel } from '@/lib/labels';
import { space } from '@/theme';

export const billTone: Record<BillStatus, BadgeTone> = { pending: 'warning', paid: 'success', canceled: 'neutral', review: 'info' };

export function BillCard({ bill, onPress }: { bill: Bill; onPress: () => void }) {
  const units = bill.items.reduce((n, i) => n + i.quantity, 0);
  return (
    <Card onPress={onPress} right={<Badge label={billStatusLabel[bill.status]} tone={billTone[bill.status]} />} title={`Ciclo ${bill.cycle}`} subtitle={formatDate(bill.issuedAt)}>
      <Row>
        <View style={styles.flex1}>
          <Text variant="small" tone="muted" numberOfLines={1}>
            {units} {units === 1 ? 'item' : 'itens'} · {paymentMethodLabel(bill)}
          </Text>
          {bill.fulfillment ? (
            <Text variant="caption" tone="dim" style={styles.mt1}>
              {fulfillmentLabel[bill.fulfillment.status]}
            </Text>
          ) : null}
        </View>
        <Money value={bill.amount} variant="heading" />
      </Row>
    </Card>
  );
}

const styles = StyleSheet.create({ flex1: { flex: 1 }, mt1: { marginTop: space(1) } });
