import type { ReactNode } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, shadows, space } from '@/theme';
import { Badge, type BadgeTone } from './Badge';
import { IconCircle, type IoniconName } from './IconCircle';
import { Text } from './Text';

// ---------- WelcomeCard ----------

interface WelcomeCardProps {
  planLabel: string;
  firstName: string;
  statusLabel: string;
  statusTone: BadgeTone;
  onLogout?: () => void;
  /** QuickActions + SavingsStrip são renderizados dentro do mesmo card branco. */
  children?: ReactNode;
}

/** Card de boas-vindas: badge "PRIME ANUAL", "Olá, {nome}" dourado, badge de status + sair. */
export function WelcomeCard({ planLabel, firstName, statusLabel, statusTone, onLogout, children }: WelcomeCardProps) {
  return (
    <View style={[styles.card, shadows.card]}>
      <View style={styles.top}>
        <View style={styles.greeting}>
          <Badge label={planLabel} tone="plan" />
          <Text variant="title" tone="gold" numberOfLines={1}>
            Olá, {firstName || 'assinante'}
          </Text>
        </View>
        <View style={styles.statusWrap}>
          <Badge label={statusLabel} tone={statusTone} />
          {onLogout ? (
            <Pressable onPress={onLogout} hitSlop={10} accessibilityRole="button" accessibilityLabel="Sair">
              <Ionicons name="log-out-outline" size={22} color={colors.text} />
            </Pressable>
          ) : null}
        </View>
      </View>
      {children}
    </View>
  );
}

// ---------- QuickActions ----------

export interface QuickAction {
  key: string;
  label: string;
  icon?: IoniconName;
  render?: ReactNode;
  onPress: () => void;
}

/** Linha de 5 círculos (#F8F9FA, ícone #495057) com rótulo em 2 linhas. */
export function QuickActions({ actions }: { actions: QuickAction[] }) {
  return (
    <View style={styles.actions}>
      {actions.map((a) => (
        <Pressable key={a.key} onPress={a.onPress} accessibilityRole="button" accessibilityLabel={a.label} style={({ pressed }) => [styles.action, pressed && styles.pressed]}>
          <IconCircle icon={a.icon} size={52} iconSize={22}>
            {a.render}
          </IconCircle>
          <Text variant="caption" tone="secondary" center numberOfLines={2} style={styles.actionLabel}>
            {a.label}
          </Text>
        </Pressable>
      ))}
    </View>
  );
}

// ---------- SavingsStrip ----------

interface SavingsStripProps {
  totalLabel?: string;
  total: string;
  periodLabel: string;
  periods: { label: string; value: string }[];
}

/** Faixa de economia (#F8F9FA): "Economia total" + valor grande; período + valores. */
export function SavingsStrip({ totalLabel = 'Economia total', total, periodLabel, periods }: SavingsStripProps) {
  return (
    <View style={styles.savings}>
      <View style={styles.savingsTotal}>
        <Text variant="small" tone="secondary">
          {totalLabel}
        </Text>
        <Text variant="heading" style={styles.savingsValue}>
          {total}
        </Text>
      </View>
      <View style={styles.savingsPeriod}>
        <Ionicons name="calendar-outline" size={18} color={colors.textSecondary} />
        <Text variant="small" tone="secondary" style={styles.periodLabel}>
          {periodLabel}
        </Text>
      </View>
      {periods.map((p) => (
        <View key={p.label} style={styles.period}>
          <Text variant="small" tone="secondary" numberOfLines={1}>
            {p.label}
          </Text>
          <Text variant="bodyStrong" numberOfLines={1}>
            {p.value}
          </Text>
        </View>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  card: { backgroundColor: colors.surface, borderRadius: radius.md, padding: space(4), marginBottom: space(3) },
  top: { flexDirection: 'row', alignItems: 'flex-start', justifyContent: 'space-between', gap: space(2) },
  greeting: { flex: 1, gap: space(1.5) },
  statusWrap: { flexDirection: 'row', alignItems: 'center', gap: space(2), marginTop: 2 },
  actions: { flexDirection: 'row', justifyContent: 'space-between', marginTop: space(4), gap: space(1) },
  action: { flex: 1, alignItems: 'center', gap: space(1.5) },
  actionLabel: { maxWidth: 64 },
  pressed: { opacity: 0.7 },
  savings: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: space(2),
    marginTop: space(4),
    backgroundColor: colors.subtle,
    borderRadius: radius.sm,
    padding: space(3),
  },
  savingsTotal: { flex: 1.2, gap: 2 },
  savingsValue: { fontSize: 20, lineHeight: 24 },
  savingsPeriod: { flexDirection: 'row', alignItems: 'center', gap: space(1), flex: 1 },
  periodLabel: { flex: 1 },
  period: { gap: 2, alignItems: 'flex-start', flex: 0.9 },
});
