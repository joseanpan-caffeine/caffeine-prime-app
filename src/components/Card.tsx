import type { ReactNode } from 'react';
import { Pressable, StyleSheet, View, type ViewStyle } from 'react-native';
import { colors, radius, space } from '@/theme';
import { Text } from './Text';

interface CardProps {
  children?: ReactNode;
  title?: string;
  subtitle?: string;
  right?: ReactNode;
  tone?: 'default' | 'accent' | 'danger' | 'success' | 'elevated';
  onPress?: () => void;
  style?: ViewStyle;
  padded?: boolean;
}

export function Card({ children, title, subtitle, right, tone = 'default', onPress, style, padded = true }: CardProps) {
  const toneStyle =
    tone === 'accent'
      ? styles.accent
      : tone === 'danger'
        ? styles.danger
        : tone === 'success'
          ? styles.success
          : tone === 'elevated'
            ? styles.elevated
            : null;
  const content = (
    <View style={[styles.card, toneStyle, padded && styles.padded, style]}>
      {title || right ? (
        <View style={styles.header}>
          <View style={styles.headerText}>
            {title ? <Text variant="heading">{title}</Text> : null}
            {subtitle ? (
              <Text variant="small" tone="muted">
                {subtitle}
              </Text>
            ) : null}
          </View>
          {right}
        </View>
      ) : null}
      {children}
    </View>
  );
  if (onPress) {
    return (
      <Pressable onPress={onPress} style={({ pressed }) => [pressed && styles.pressed]} accessibilityRole="button">
        {content}
      </Pressable>
    );
  }
  return content;
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: colors.surface,
    borderRadius: radius.lg,
    borderWidth: 1,
    borderColor: colors.border,
    marginBottom: space(3),
  },
  padded: { padding: space(4) },
  accent: { borderColor: colors.accent, backgroundColor: '#1E1710' },
  danger: { borderColor: colors.danger, backgroundColor: '#231512' },
  success: { borderColor: colors.success, backgroundColor: '#15201A' },
  elevated: { backgroundColor: colors.surfaceElevated, borderColor: colors.borderStrong },
  header: { flexDirection: 'row', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: space(3), gap: space(2) },
  headerText: { flex: 1, gap: 2 },
  pressed: { opacity: 0.85 },
});
