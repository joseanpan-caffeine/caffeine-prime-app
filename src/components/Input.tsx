import { forwardRef, type ReactNode } from 'react';
import { StyleSheet, TextInput, View, type TextInputProps } from 'react-native';
import { colors, radius, space, textStyle } from '@/theme';
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
        <Text variant="small" tone="secondary" style={styles.label}>
          {label}
        </Text>
      ) : null}
      <View style={[styles.field, !!error && styles.fieldError]}>
        <TextInput
          ref={ref}
          placeholderTextColor={colors.textMuted}
          selectionColor={colors.gold}
          keyboardAppearance="light"
          style={[styles.input, textStyle('body'), style]}
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
  label: {},
  field: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.surface,
    borderRadius: radius.sm,
    borderWidth: 1,
    borderColor: colors.borderStrong,
    paddingHorizontal: space(3),
  },
  fieldError: { borderColor: colors.danger },
  input: { flex: 1, color: colors.text, fontSize: 14, paddingVertical: space(2.5), minHeight: 44 },
});
