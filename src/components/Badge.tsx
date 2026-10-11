import { StyleSheet, View, type ViewStyle } from 'react-native';
import { colors, radius, space } from '@/theme';
import { Text } from './Text';

/**
 * Badges do Figma "Atoms":
 * - plan: "PRIME ANUAL" (bg #DDA41F, texto #260F0F, caixa alta, radius 4)
 * - status (pill): active / paused / pending / review / scheduled / canceled
 * - editAvailable / editUnavailable
 * - exclusive ("EXCLUSIVO PRIME"), launch ("LANÇAMENTO"), off ("15% OFF" verde), offDark ("20% OFF" escuro)
 * - save ("ECONOMIZE R$ …")
 * - tipo de pedido: orderSubscription / orderEcommerce / orderResend
 * Tons legados (neutral/accent/success/danger/info/warning) continuam aceitos.
 */
export type BadgeTone =
  | 'plan'
  | 'active'
  | 'paused'
  | 'pending'
  | 'review'
  | 'scheduled'
  | 'canceled'
  | 'editAvailable'
  | 'editUnavailable'
  | 'exclusive'
  | 'launch'
  | 'off'
  | 'offDark'
  | 'save'
  | 'orderSubscription'
  | 'orderEcommerce'
  | 'orderResend'
  | 'neutral'
  | 'accent'
  | 'success'
  | 'danger'
  | 'info'
  | 'warning';

interface BadgeProps {
  label: string;
  tone?: BadgeTone;
  style?: ViewStyle;
  size?: 'sm' | 'md';
}

interface Spec {
  bg: string;
  fg: string;
  border?: string;
  shape: 'pill' | 'square';
  uppercase?: boolean;
}

const specs: Record<BadgeTone, Spec> = {
  plan: { bg: colors.goldDeep, fg: colors.brandDark, shape: 'square', uppercase: true },
  active: { bg: colors.successBadge, fg: colors.successText, border: colors.success, shape: 'pill' },
  paused: { bg: colors.warningSoft, fg: colors.warningText, border: '#FFD43B', shape: 'pill' },
  pending: { bg: colors.dangerSoft, fg: colors.danger, border: '#FFA8A8', shape: 'pill' },
  review: { bg: colors.infoSoft, fg: colors.info, border: '#99E9F2', shape: 'pill' },
  scheduled: { bg: colors.infoSoft, fg: colors.info, border: '#99E9F2', shape: 'pill' },
  canceled: { bg: colors.muted, fg: colors.textMuted, border: colors.borderStrong, shape: 'pill' },
  editAvailable: { bg: colors.infoSoft, fg: colors.info, border: '#99E9F2', shape: 'pill' },
  editUnavailable: { bg: colors.warningSoft, fg: colors.warningText, border: '#FFD43B', shape: 'pill' },
  exclusive: { bg: colors.primaryStrong, fg: colors.brandDark, shape: 'square', uppercase: true },
  launch: { bg: colors.surface, fg: colors.text, border: colors.text, shape: 'square', uppercase: true },
  off: { bg: colors.successDeep, fg: '#FFFFFF', shape: 'square', uppercase: true },
  offDark: { bg: colors.brandDark, fg: '#FFFFFF', shape: 'square', uppercase: true },
  save: { bg: colors.successDeep, fg: '#FFFFFF', shape: 'square', uppercase: true },
  orderSubscription: { bg: colors.goldDeep, fg: colors.brandDark, shape: 'square', uppercase: true },
  orderEcommerce: { bg: colors.brandDark, fg: '#FFFFFF', shape: 'square', uppercase: true },
  orderResend: { bg: colors.warning, fg: colors.brandDark, shape: 'square', uppercase: true },
  neutral: { bg: colors.muted, fg: colors.textSecondary, shape: 'pill' },
  accent: { bg: colors.goldSoft, fg: colors.gold, border: colors.primary, shape: 'pill' },
  success: { bg: colors.successBadge, fg: colors.successText, border: colors.success, shape: 'pill' },
  danger: { bg: colors.dangerSoft, fg: colors.danger, border: '#FFA8A8', shape: 'pill' },
  info: { bg: colors.infoSoft, fg: colors.info, border: '#99E9F2', shape: 'pill' },
  warning: { bg: colors.warningSoft, fg: colors.warningText, border: '#FFD43B', shape: 'pill' },
};

export function Badge({ label, tone = 'neutral', style, size = 'md' }: BadgeProps) {
  const s = specs[tone];
  return (
    <View
      style={[
        styles.badge,
        s.shape === 'pill' ? styles.pill : styles.square,
        { backgroundColor: s.bg, borderColor: s.border ?? s.bg },
        size === 'sm' && styles.sm,
        style,
      ]}
    >
      <Text variant={s.shape === 'square' ? 'captionStrong' : 'caption'} style={{ color: s.fg, letterSpacing: s.uppercase ? 0.2 : 0 }} numberOfLines={1}>
        {s.uppercase ? label.toUpperCase() : label}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  badge: {
    alignSelf: 'flex-start',
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    paddingHorizontal: space(2),
    paddingVertical: 3,
  },
  pill: { borderRadius: radius.pill, paddingHorizontal: space(2.5) },
  square: { borderRadius: radius.xs },
  sm: { paddingHorizontal: space(1.5), paddingVertical: 2 },
});
