import type { ReactNode } from 'react';
import { Pressable, StyleSheet, View, type ViewStyle } from 'react-native';
import { colors, radius, shadows, space } from '@/theme';
import { Text } from './Text';

export type CardTone = 'default' | 'subtle' | 'dark' | 'danger' | 'warning' | 'info' | 'success' | 'purple' | 'accent' | 'elevated';

interface CardProps {
  children?: ReactNode;
  title?: string;
  subtitle?: string;
  right?: ReactNode;
  tone?: CardTone;
  onPress?: () => void;
  style?: ViewStyle;
  padded?: boolean;
  /** Sem sombra/borda (para aninhar em outro card). */
  flat?: boolean;
}

const toneStyles: Record<CardTone, ViewStyle> = {
  default: { backgroundColor: colors.surface },
  elevated: { backgroundColor: colors.surface },
  subtle: { backgroundColor: colors.subtle },
  dark: { backgroundColor: colors.brandDark },
  danger: { backgroundColor: colors.surface, borderColor: '#FFC9C9', borderWidth: 1 },
  warning: { backgroundColor: colors.warningCard },
  info: { backgroundColor: colors.surface },
  success: { backgroundColor: colors.surface },
  purple: { backgroundColor: colors.purpleSoft },
  accent: { backgroundColor: colors.goldSoft },
};

export function Card({ children, title, subtitle, right, tone = 'default', onPress, style, padded = true, flat = false }: CardProps) {
  const dark = tone === 'dark';
  const content = (
    <View style={[styles.card, !flat && shadows.card, toneStyles[tone], padded && styles.padded, style]}>
      {title || right ? (
        <View style={styles.header}>
          <View style={styles.headerText}>
            {title ? (
              <Text variant="subheading" tone={dark ? 'onDark' : 'default'}>
                {title}
              </Text>
            ) : null}
            {subtitle ? (
              <Text variant="small" tone={dark ? 'onDarkMuted' : 'muted'}>
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
    borderRadius: radius.md,
    marginBottom: space(3),
  },
  padded: { padding: space(4) },
  header: { flexDirection: 'row', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: space(3), gap: space(2) },
  headerText: { flex: 1, gap: 2 },
  pressed: { opacity: 0.85 },
});
