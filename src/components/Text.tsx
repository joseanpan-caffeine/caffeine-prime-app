import { Text as RNText, type TextProps as RNTextProps, StyleSheet } from 'react-native';
import { colors, typography } from '@/theme';

export type TextVariant = keyof typeof typography;
export type TextTone = 'default' | 'muted' | 'dim' | 'accent' | 'success' | 'danger' | 'onAccent';

export interface TextProps extends RNTextProps {
  variant?: TextVariant;
  tone?: TextTone;
  center?: boolean;
}

const toneColor: Record<TextTone, string> = {
  default: colors.text,
  muted: colors.textMuted,
  dim: colors.textDim,
  accent: colors.accent,
  success: colors.success,
  danger: colors.danger,
  onAccent: colors.onAccent,
};

export function Text({ variant = 'body', tone = 'default', center, style, ...rest }: TextProps) {
  return (
    <RNText
      {...rest}
      style={[typography[variant], { color: toneColor[tone] }, center && styles.center, style]}
    />
  );
}

const styles = StyleSheet.create({ center: { textAlign: 'center' } });
