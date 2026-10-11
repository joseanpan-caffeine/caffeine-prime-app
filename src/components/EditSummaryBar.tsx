import { useState, type ReactNode } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, space } from '@/theme';
import { Badge } from './Badge';
import { Button } from './Button';
import { Text } from './Text';

export interface SummaryLine {
  key: string;
  label: string;
  priceLabel: string;
  discountPercentage?: number;
}

interface EditSummaryBarProps {
  totalLabel: string;
  /** Sufixo depois do total ("/mês"). */
  periodLabel?: string;
  fullTotalLabel?: string;
  itemsCount: number;
  lines?: SummaryLine[];
  savingsLabel?: string;
  addedCount?: number;
  removedCount?: number;
  confirmLabel?: string;
  onConfirm: () => void;
  confirmDisabled?: boolean;
  confirmLoading?: boolean;
  onDiscard?: () => void;
  /** Avisos (preview) acima da barra. */
  warnings?: ReactNode;
  calculating?: boolean;
}

/**
 * Resumo de edição (sticky inferior): "Total R$ 390,49/mês ~~R$ 590,49~~", "3 itens · Ver todos ↗",
 * badge "ECONOMIZE R$ 126,98", "● 1 item adicionado", botão verde "Confirmar edição da assinatura".
 */
export function EditSummaryBar({ totalLabel, periodLabel = '/mês', fullTotalLabel, itemsCount, lines = [], savingsLabel, addedCount = 0, removedCount = 0, confirmLabel = 'Confirmar edição da assinatura', onConfirm, confirmDisabled, confirmLoading, onDiscard, warnings, calculating }: EditSummaryBarProps) {
  const [open, setOpen] = useState(false);
  return (
    <View style={styles.root}>
      {warnings}
      <View style={styles.top}>
        <View style={styles.left}>
          <Text variant="caption" tone="secondary">
            Total{calculating ? ' · calculando…' : ''}
          </Text>
          <View style={styles.totalRow}>
            <Text variant="heading">{totalLabel}</Text>
            <Text variant="small" tone="secondary">
              {periodLabel}
            </Text>
            {fullTotalLabel ? (
              <Text variant="small" tone="dim" style={styles.strike}>
                {fullTotalLabel}
              </Text>
            ) : null}
          </View>
          <View style={styles.itemsRow}>
            <Text variant="small" tone="secondary">
              {itemsCount} {itemsCount === 1 ? 'item' : 'itens'}
            </Text>
            {lines.length > 0 ? (
              <>
                <Text variant="small" tone="secondary">
                  {' '}
                  ·{' '}
                </Text>
                <Pressable onPress={() => setOpen((v) => !v)} accessibilityRole="button" accessibilityState={{ expanded: open }} style={styles.seeAll}>
                  <Text variant="small" style={styles.underline}>
                    Ver todos
                  </Text>
                  <Ionicons name={open ? 'chevron-up' : 'open-outline'} size={12} color={colors.text} />
                </Pressable>
              </>
            ) : null}
          </View>
        </View>
        <View style={styles.right}>
          {savingsLabel ? <Badge label={`Economize ${savingsLabel}`} tone="save" /> : null}
          {addedCount > 0 ? (
            <View style={styles.dotRow}>
              <View style={[styles.dot, { backgroundColor: colors.warning }]} />
              <Text variant="small">
                {addedCount} {addedCount === 1 ? 'item adicionado' : 'itens adicionados'}
              </Text>
            </View>
          ) : null}
          {removedCount > 0 ? (
            <View style={styles.dotRow}>
              <View style={[styles.dot, { backgroundColor: colors.danger }]} />
              <Text variant="small">
                {removedCount} {removedCount === 1 ? 'item removido' : 'itens removidos'}
              </Text>
            </View>
          ) : null}
        </View>
      </View>
      {open && lines.length > 0 ? (
        <View style={styles.lines}>
          {lines.map((l) => (
            <View key={l.key} style={styles.line}>
              <Text variant="caption" tone="secondary" numberOfLines={1} style={styles.lineLabel}>
                {l.label}
              </Text>
              <Text variant="caption" tone="secondary">
                {l.priceLabel}
              </Text>
              {l.discountPercentage ? <Badge label={`${l.discountPercentage}% OFF`} tone="offDark" size="sm" /> : null}
            </View>
          ))}
        </View>
      ) : null}
      <View style={styles.actions}>
        {onDiscard ? <Button title="Descartar" variant="ghost" size="sm" full={false} onPress={onDiscard} /> : null}
        <Button title={confirmLabel} variant="success" onPress={onConfirm} disabled={confirmDisabled} loading={confirmLoading} style={styles.confirm} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { gap: space(2) },
  top: { flexDirection: 'row', alignItems: 'flex-start', justifyContent: 'space-between', gap: space(2) },
  left: { flex: 1, gap: 1 },
  totalRow: { flexDirection: 'row', alignItems: 'baseline', gap: space(1), flexWrap: 'wrap' },
  strike: { textDecorationLine: 'line-through' },
  itemsRow: { flexDirection: 'row', alignItems: 'center' },
  seeAll: { flexDirection: 'row', alignItems: 'center', gap: 3 },
  underline: { textDecorationLine: 'underline' },
  right: { alignItems: 'flex-end', gap: space(1.5) },
  dotRow: { flexDirection: 'row', alignItems: 'center', gap: space(1.5) },
  dot: { width: 8, height: 8, borderRadius: 4 },
  lines: { gap: space(1.5), paddingVertical: space(1) },
  line: { flexDirection: 'row', alignItems: 'center', gap: space(2) },
  lineLabel: { flex: 1 },
  actions: { flexDirection: 'row', alignItems: 'center', gap: space(2) },
  confirm: { flex: 1 },
});
