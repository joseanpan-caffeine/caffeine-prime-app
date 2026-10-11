import type { ReactNode } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, shadows, space } from '@/theme';
import { Button } from './Button';
import { type IoniconName } from './IconCircle';
import { Text } from './Text';

export type AlertVariant =
  | 'in_transit'
  | 'delivered'
  | 'preparing'
  | 'scheduled'
  | 'why_cant_edit'
  | 'payment_pending'
  | 'payment_failed'
  | 'paused'
  | 'under_review'
  | 'canceled'
  | 'info';

interface AlertItem {
  quantity: number;
  label: string;
}

interface AlertCardProps {
  variant: AlertVariant;
  title: string;
  /** Texto principal (string ou nós com <Text> em negrito). */
  children?: ReactNode;
  items?: AlertItem[];
  /** Nota em cinza no rodapé com ícone ⓘ. */
  note?: ReactNode;
  /** Link "Rastrear pedido ↗". */
  linkLabel?: string;
  onLink?: () => void;
  /** Pergunta acima do botão ("Deseja editar sua próxima caixa?"). */
  question?: string;
  primaryLabel?: string;
  onPrimary?: () => void;
  primaryLoading?: boolean;
  secondaryLabel?: string;
  onSecondary?: () => void;
  onDismiss?: () => void;
}

interface Spec {
  icon: IoniconName;
  titleColor: string;
  bg: string;
  border?: string;
  buttonVariant: 'dark' | 'primary' | 'secondary';
}

const specs: Record<AlertVariant, Spec> = {
  in_transit: { icon: 'car-outline', titleColor: colors.successText, bg: colors.subtle, buttonVariant: 'dark' },
  delivered: { icon: 'home-outline', titleColor: colors.successText, bg: colors.subtle, buttonVariant: 'dark' },
  preparing: { icon: 'cube-outline', titleColor: colors.successText, bg: colors.subtle, buttonVariant: 'dark' },
  scheduled: { icon: 'cube-outline', titleColor: colors.successText, bg: colors.subtle, buttonVariant: 'dark' },
  why_cant_edit: { icon: 'lock-closed-outline', titleColor: colors.successText, bg: colors.subtle, buttonVariant: 'dark' },
  payment_pending: { icon: 'card-outline', titleColor: colors.danger, bg: colors.surface, border: '#FFC9C9', buttonVariant: 'primary' },
  payment_failed: { icon: 'alert-circle-outline', titleColor: colors.danger, bg: colors.surface, border: '#FFC9C9', buttonVariant: 'primary' },
  paused: { icon: 'pause-outline', titleColor: colors.warningText, bg: colors.warningCard, buttonVariant: 'primary' },
  under_review: { icon: 'search-outline', titleColor: colors.info, bg: colors.surface, buttonVariant: 'primary' },
  canceled: { icon: 'heart-dislike-outline', titleColor: colors.text, bg: colors.surface, buttonVariant: 'primary' },
  info: { icon: 'information-circle-outline', titleColor: colors.text, bg: colors.subtle, buttonVariant: 'dark' },
};

/** Cards de alerta do Figma (ícone à esquerda, título bold colorido, corpo, itens, link, botão). */
export function AlertCard({ variant, title, children, items, note, linkLabel, onLink, question, primaryLabel, onPrimary, primaryLoading, secondaryLabel, onSecondary, onDismiss }: AlertCardProps) {
  const s = specs[variant];
  return (
    <View style={[styles.card, shadows.card, { backgroundColor: s.bg }, s.border ? { borderWidth: 1, borderColor: s.border } : null]}>
      <View style={styles.head}>
        <Ionicons name={s.icon} size={20} color={s.titleColor} style={styles.icon} />
        <Text variant="bodyStrong" style={[styles.title, { color: s.titleColor }]}>
          {title}
        </Text>
        {onDismiss ? (
          <Pressable onPress={onDismiss} hitSlop={10} accessibilityRole="button" accessibilityLabel="Fechar">
            <Ionicons name="close" size={18} color={colors.text} />
          </Pressable>
        ) : null}
      </View>
      <View style={styles.body}>
        {typeof children === 'string' ? (
          <Text variant="body" tone="secondary">
            {children}
          </Text>
        ) : (
          children
        )}
        {items && items.length > 0 ? (
          <View style={styles.items}>
            {items.map((it, i) => (
              <View key={`${it.label}-${i}`} style={styles.item}>
                <View style={styles.qty}>
                  <Text variant="captionStrong" tone="successText">
                    {it.quantity}
                  </Text>
                </View>
                <Text variant="small" tone="secondary" numberOfLines={1} style={styles.itemLabel}>
                  {it.label}
                </Text>
              </View>
            ))}
          </View>
        ) : null}
        {linkLabel && onLink ? (
          <Pressable onPress={onLink} accessibilityRole="link" style={styles.link}>
            <Text variant="smallMedium" style={styles.linkText}>
              {linkLabel}
            </Text>
            <Ionicons name="open-outline" size={14} color={colors.text} />
          </Pressable>
        ) : null}
        {note ? (
          <View style={styles.note}>
            <Ionicons name="information-circle-outline" size={14} color={colors.textMuted} />
            {typeof note === 'string' ? (
              <Text variant="caption" tone="dim" style={styles.noteText}>
                {note}
              </Text>
            ) : (
              note
            )}
          </View>
        ) : null}
      </View>
      {question ? (
        <Text variant="small" tone="secondary" style={styles.question}>
          {question}
        </Text>
      ) : null}
      {primaryLabel && onPrimary ? (
        <View style={styles.actions}>
          <Button title={primaryLabel} variant={s.buttonVariant} size="sm" onPress={onPrimary} loading={primaryLoading} full={variant !== 'paused'} style={variant === 'paused' ? styles.pausedBtn : undefined} />
          {secondaryLabel && onSecondary ? <Button title={secondaryLabel} variant="secondary" size="sm" onPress={onSecondary} icon={variant.startsWith('payment') ? <Ionicons name="headset-outline" size={16} color={colors.text} /> : undefined} /> : null}
        </View>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  card: { borderRadius: radius.md, padding: space(4), marginBottom: space(3), gap: space(2) },
  head: { flexDirection: 'row', alignItems: 'center', gap: space(2) },
  icon: { width: 22 },
  title: { flex: 1 },
  body: { marginLeft: 30, gap: space(2) },
  items: { gap: space(1.5) },
  item: { flexDirection: 'row', alignItems: 'center', gap: space(2) },
  qty: { minWidth: 18, height: 18, paddingHorizontal: 4, borderRadius: 3, backgroundColor: colors.successSoft, alignItems: 'center', justifyContent: 'center' },
  itemLabel: { flex: 1 },
  link: { flexDirection: 'row', alignItems: 'center', gap: space(1), alignSelf: 'flex-start' },
  linkText: { textDecorationLine: 'underline' },
  note: { flexDirection: 'row', alignItems: 'center', gap: space(1) },
  noteText: { flex: 1 },
  question: { marginTop: space(1) },
  actions: { gap: space(2), marginTop: space(1) },
  pausedBtn: { alignSelf: 'center', minWidth: 170 },
});
