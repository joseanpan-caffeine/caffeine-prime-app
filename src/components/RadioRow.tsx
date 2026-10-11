import type { ReactNode } from 'react';
import { Pressable, StyleSheet, View, type ViewStyle } from 'react-native';
import { colors, radius, space } from '@/theme';
import { Text } from './Text';

interface RadioProps {
  selected: boolean;
  disabled?: boolean;
}

/** Bolinha de rádio dourada (Figma). */
export function Radio({ selected, disabled }: RadioProps) {
  return (
    <View style={[styles.radio, selected && styles.radioOn, disabled && styles.disabled]}>{selected ? <View style={styles.radioDot} /> : null}</View>
  );
}

interface RadioRowProps {
  label: string;
  hint?: string;
  selected: boolean;
  onPress: () => void;
  disabled?: boolean;
  right?: ReactNode;
  /** Linha com borda e fundo amarelo-claro quando selecionada (cartões / tamanhos). */
  boxed?: boolean;
  style?: ViewStyle;
}

export function RadioRow({ label, hint, selected, onPress, disabled, right, boxed, style }: RadioRowProps) {
  return (
    <Pressable
      onPress={onPress}
      disabled={disabled}
      accessibilityRole="radio"
      accessibilityState={{ selected, disabled: !!disabled }}
      style={({ pressed }) => [styles.row, boxed && styles.boxed, boxed && selected && styles.boxedOn, pressed && !disabled && styles.pressed, disabled && styles.disabled, style]}
    >
      <Radio selected={selected} disabled={disabled} />
      <View style={styles.text}>
        <Text variant={boxed ? 'body' : 'small'}>{label}</Text>
        {hint ? (
          <Text variant="caption" tone="dim">
            {hint}
          </Text>
        ) : null}
      </View>
      {right}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', alignItems: 'center', gap: space(2.5), paddingVertical: space(2) },
  boxed: { paddingHorizontal: space(3), paddingVertical: space(3), borderRadius: radius.sm, borderWidth: 1, borderColor: colors.borderStrong, backgroundColor: colors.surface, marginBottom: space(2) },
  boxedOn: { borderColor: colors.primary, backgroundColor: '#FFFBEB' },
  text: { flex: 1, gap: 1 },
  radio: { width: 18, height: 18, borderRadius: 9, borderWidth: 1.5, borderColor: colors.borderStrong, alignItems: 'center', justifyContent: 'center', backgroundColor: colors.surface },
  radioOn: { borderColor: colors.gold, backgroundColor: colors.gold },
  radioDot: { width: 7, height: 7, borderRadius: 4, backgroundColor: '#FFFFFF' },
  pressed: { opacity: 0.7 },
  disabled: { opacity: 0.5 },
});
