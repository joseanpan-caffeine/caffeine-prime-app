import { StyleSheet, View, type ViewStyle } from 'react-native';
import { colors, radius, space } from '@/theme';
import { Text } from './Text';

export type BadgeTone = 'neutral' | 'accent' | 'success' | 'danger' | 'info' | 'warning';

interface BadgeProps {
  label: string;
  tone?: BadgeTone;
  style?: ViewStyle;
}

const palette: Record<BadgeTone, { bg: string; fg: string }> = {
  neutral: { bg: colors.surfaceElevated, fg: colors.textMuted },
  accent: { bg: colors.accentSoft, fg: colors.accent },
  success: { bg: colors.successSoft, fg: colors.success },
  danger: { bg: colors.dangerSoft, fg: colors.danger },
  info: { bg: colors.infoSoft, fg: colors.info },
  warning: { bg: colors.warningSoft, fg: colors.warning },
};

export function Badge({ label, tone = 'neutral', style }: BadgeProps) {
  const p = palette[tone];
  return (
    <View style={[styles.badge, { backgroundColor: p.bg }, style]}>
      <View style={[styles.dot, { backgroundColor: p.fg }]} />
      <Text variant="caption" style={{ color: p.fg, textTransform: 'uppercase' }}>
        {label}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  badge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: space(1.5),
    paddingHorizontal: space(2.5),
    paddingVertical: space(1),
    borderRadius: radius.pill,
    alignSelf: 'flex-start',
  },
  dot: { width: 6, height: 6, borderRadius: 3 },
});
