import { Text as RNText, type TextProps as RNTextProps, StyleSheet } from 'react-native';
import { colors, textStyle, type TypeVariant } from '@/theme';

export type TextVariant = TypeVariant;
export type TextTone =
  | 'default'
  | 'secondary'
  | 'muted'
  | 'dim'
  | 'gold'
  | 'accent'
  | 'purple'
  | 'success'
  | 'successText'
  | 'warning'
  | 'danger'
  | 'info'
  | 'onDark'
  | 'onDarkMuted'
  | 'onAccent'
  | 'onPrimary';

export interface TextProps extends RNTextProps {
  variant?: TextVariant;
  tone?: TextTone;
  center?: boolean;
}

const toneColor: Record<TextTone, string> = {
  default: colors.text,
  secondary: colors.textSecondary,
  muted: colors.textSecondary,
  dim: colors.textMuted,
  gold: colors.gold,
  accent: colors.gold,
  purple: colors.purple,
  success: colors.success,
  successText: colors.successText,
  warning: colors.warningText,
  danger: colors.danger,
  info: colors.info,
  onDark: colors.textOnDark,
  onDarkMuted: colors.textOnDarkMuted,
  onAccent: colors.textOnPrimary,
  onPrimary: colors.textOnPrimary,
};

export function Text({ variant = 'body', tone = 'default', center, style, ...rest }: TextProps) {
  return <RNText {...rest} style={[textStyle(variant), { color: toneColor[tone] }, center && styles.center, style]} />;
}

const styles = StyleSheet.create({ center: { textAlign: 'center' } });
