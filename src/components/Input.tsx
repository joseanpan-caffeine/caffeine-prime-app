import { forwardRef, type ReactNode } from 'react';
import { StyleSheet, TextInput, View, type TextInputProps } from 'react-native';
import { colors, radius, space, typography } from '@/theme';
import { Text } from './Text';

export interface InputProps extends TextInputProps {
  label?: string;
  error?: string;
  hint?: string;
  right?: ReactNode;
}

export const Input = forwardRef<TextInput, InputProps>(function Input({ label, error, hint, right, style, ...rest }, ref) {
  return (
    <View style={styles.wrap}>
      {label ? (
        <Text variant="caption" tone="muted" style={styles.label}>
          {label.toUpperCase()}
        </Text>
      ) : null}
      <View style={[styles.field, !!error && styles.fieldError]}>
        <TextInput
          ref={ref}
          placeholderTextColor={colors.textDim}
          selectionColor={colors.accent}
          keyboardAppearance="dark"
          style={[styles.input, style]}
          {...rest}
        />
        {right}
      </View>
      {error ? (
        <Text variant="caption" tone="danger">
          {error}
        </Text>
      ) : hint ? (
        <Text variant="caption" tone="dim">
          {hint}
        </Text>
      ) : null}
    </View>
  );
});

const styles = StyleSheet.create({
  wrap: { gap: space(1.5), marginBottom: space(3) },
  label: { letterSpacing: 0.8 },
  field: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.surfaceElevated,
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: colors.borderStrong,
    paddingHorizontal: space(3),
  },
  fieldError: { borderColor: colors.danger },
  input: { flex: 1, ...typography.body, color: colors.text, paddingVertical: space(3), minHeight: 50 },
});
