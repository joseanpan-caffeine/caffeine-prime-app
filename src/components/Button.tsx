import type { ReactNode } from 'react';
import { ActivityIndicator, Pressable, StyleSheet, View, type ViewStyle } from 'react-native';
import { colors, radius, space } from '@/theme';
import { Text } from './Text';

/**
 * Variantes (Figma "Atoms"):
 * primary  — amarelo #F1D98A, texto #260F0F
 * secondary — branco com borda #F1D98A
 * ghost — só texto escuro
 * danger — só texto vermelho
 * success — verde #82C91E, texto branco ("Confirmar edição")
 * purple — roxo #7B44DA ("Resgatar")
 * dark — #260F0F, texto branco ("Editar caixa" nos alertas)
 * gold — gradiente dourado (aproximado por #D9A93E) dentro do card escuro
 */
export type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'danger' | 'success' | 'purple' | 'dark' | 'gold';
export type ButtonSize = 'md' | 'sm' | 'xs';

interface ButtonProps {
  title: string;
  onPress?: () => void;
  variant?: ButtonVariant;
  size?: ButtonSize;
  loading?: boolean;
  disabled?: boolean;
  icon?: ReactNode;
  style?: ViewStyle;
  full?: boolean;
  accessibilityLabel?: string;
}

const textColor: Record<ButtonVariant, string> = {
  primary: colors.textOnPrimary,
  secondary: colors.textOnPrimary,
  ghost: colors.textOnPrimary,
  danger: colors.danger,
  success: '#FFFFFF',
  purple: '#FFFFFF',
  dark: '#FFFFFF',
  gold: colors.textOnPrimary,
};

export function Button({
  title,
  onPress,
  variant = 'primary',
  size = 'md',
  loading = false,
  disabled = false,
  icon,
  style,
  full = true,
  accessibilityLabel,
}: ButtonProps) {
  const isDisabled = disabled || loading;
  const color = isDisabled && variant !== 'ghost' && variant !== 'danger' ? colors.textMuted : textColor[variant];
  return (
    <Pressable
      onPress={onPress}
      disabled={isDisabled}
      accessibilityRole="button"
      accessibilityLabel={accessibilityLabel ?? title}
      accessibilityState={{ disabled: isDisabled, busy: loading }}
      style={({ pressed }) => [
        styles.base,
        styles[variant],
        size === 'sm' && styles.sm,
        size === 'xs' && styles.xs,
        full && styles.full,
        pressed && !isDisabled && styles.pressed,
        isDisabled && (variant === 'ghost' || variant === 'danger' ? styles.disabledText : styles.disabled),
        style,
      ]}
    >
      <View style={styles.content}>
        {loading ? (
          <ActivityIndicator color={color} size="small" />
        ) : (
          <>
            {icon}
            <Text variant={size === 'md' ? 'bodyMedium' : 'smallMedium'} style={{ color }}>
              {title}
            </Text>
          </>
        )}
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  base: {
    minHeight: 44,
    paddingHorizontal: space(4),
    borderRadius: radius.sm,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: 'transparent',
  },
  sm: { minHeight: 36, paddingHorizontal: space(3) },
  xs: { minHeight: 28, paddingHorizontal: space(2.5), borderRadius: radius.xs },
  full: { alignSelf: 'stretch' },
  content: { flexDirection: 'row', alignItems: 'center', gap: space(2) },
  primary: { backgroundColor: colors.primary },
  secondary: { backgroundColor: colors.surface, borderColor: colors.primary },
  ghost: { backgroundColor: 'transparent' },
  danger: { backgroundColor: 'transparent' },
  success: { backgroundColor: colors.success },
  purple: { backgroundColor: colors.purple },
  dark: { backgroundColor: colors.brandDark },
  gold: { backgroundColor: '#D9A93E', borderColor: '#E4BD6F' },
  pressed: { opacity: 0.85 },
  disabled: { backgroundColor: colors.muted, borderColor: colors.muted },
  disabledText: { opacity: 0.45 },
});
