import type { ReactNode } from 'react';
import { Pressable, StyleSheet, View, type ViewStyle } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, shadows, space } from '@/theme';
import { type IoniconName } from './IconCircle';
import { Text } from './Text';

interface SectionListProps {
  /** Título 14px bold cinza-escuro fora do card. */
  title?: string;
  children: ReactNode;
  style?: ViewStyle;
}

/** Lista de seção do Figma: título fora + card branco com linhas separadas por #E9ECEF. */
export function SectionList({ title, children, style }: SectionListProps) {
  return (
    <View style={[styles.section, style]} onLayout={undefined}>
      {title ? (
        <Text variant="bodyStrong" tone="secondary" style={styles.title}>
          {title}
        </Text>
      ) : null}
      <View style={[styles.card, shadows.card]}>{children}</View>
    </View>
  );
}

interface SectionRowProps {
  icon?: IoniconName;
  iconNode?: ReactNode;
  title: string;
  subtitle?: ReactNode;
  onPress?: () => void;
  chevron?: boolean;
  danger?: boolean;
  disabled?: boolean;
  right?: ReactNode;
  /** Conteúdo expandido abaixo da linha (ex.: "Meu plano"). */
  expanded?: ReactNode;
  last?: boolean;
}

/** Linha: ícone dourado 20px, título bold 14, subtítulo 12 cinza, chevron à direita. */
export function SectionRow({ icon, iconNode, title, subtitle, onPress, chevron = true, danger, disabled, right, expanded, last }: SectionRowProps) {
  const iconColor = danger ? colors.danger : disabled ? colors.textMuted : colors.gold;
  const body = (
    <View style={[styles.row, !last && styles.border]}>
      <View style={styles.main}>
        <View style={styles.icon}>{iconNode ?? (icon ? <Ionicons name={icon} size={20} color={iconColor} /> : null)}</View>
        <View style={styles.text}>
          <Text variant="bodyStrong" tone={danger ? 'danger' : disabled ? 'dim' : 'default'} numberOfLines={2}>
            {title}
          </Text>
          {subtitle ? (
            typeof subtitle === 'string' ? (
              <Text variant="small" tone={disabled ? 'dim' : 'secondary'} numberOfLines={2}>
                {subtitle}
              </Text>
            ) : (
              subtitle
            )
          ) : null}
        </View>
        {right}
        {chevron && (onPress || expanded !== undefined) ? <Ionicons name="chevron-forward" size={18} color={disabled ? colors.textMuted : colors.text} /> : null}
      </View>
      {expanded ? <View style={styles.expanded}>{expanded}</View> : null}
    </View>
  );
  if (!onPress) return body;
  return (
    <Pressable onPress={onPress} disabled={disabled} accessibilityRole="button" accessibilityState={{ disabled: !!disabled }} style={({ pressed }) => pressed && styles.pressed}>
      {body}
    </Pressable>
  );
}

interface PlanDetailsProps {
  planLabel: string;
  sinceLabel: string;
  /** 0–1 (fração da vigência cumprida). */
  progress: number;
  remainingLabel: string;
}

/** Conteúdo expandido de "Meu plano": Plano atual / Assinante desde / barra de vigência. */
export function PlanDetails({ planLabel, sinceLabel, progress, remainingLabel }: PlanDetailsProps) {
  const pct = Math.max(0, Math.min(1, progress));
  return (
    <View style={styles.plan}>
      <View style={styles.planCols}>
        <View style={styles.planCol}>
          <Text variant="caption" tone="secondary">
            Plano atual
          </Text>
          <Text variant="bodyStrong">{planLabel}</Text>
        </View>
        <View style={styles.planCol}>
          <Text variant="caption" tone="secondary">
            Assinante desde
          </Text>
          <Text variant="bodyStrong">{sinceLabel}</Text>
        </View>
      </View>
      <Text variant="caption" tone="secondary">
        Vigência
      </Text>
      <View style={styles.bar}>
        <View style={[styles.barFill, { width: `${Math.round(pct * 100)}%` }]} />
      </View>
      <Text variant="caption" tone="dim">
        {remainingLabel}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  section: { marginBottom: space(3) },
  title: { marginBottom: space(2) },
  card: { backgroundColor: colors.surface, borderRadius: radius.md, paddingHorizontal: space(4) },
  row: { paddingVertical: space(3.5) },
  border: { borderBottomWidth: 1, borderBottomColor: colors.border },
  main: { flexDirection: 'row', alignItems: 'center', gap: space(3) },
  icon: { width: 24, alignItems: 'center' },
  text: { flex: 1, gap: 3 },
  expanded: { marginTop: space(3), marginLeft: 36 },
  pressed: { opacity: 0.7 },
  plan: { gap: space(1.5) },
  planCols: { flexDirection: 'row', gap: space(4), marginBottom: space(2) },
  planCol: { flex: 1, gap: 2 },
  bar: { height: 6, borderRadius: 3, backgroundColor: colors.muted, overflow: 'hidden' },
  barFill: { height: '100%', backgroundColor: colors.warning, borderRadius: 3 },
});
