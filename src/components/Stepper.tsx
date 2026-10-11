import { Pressable, StyleSheet, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, space } from '@/theme';
import { Text } from './Text';

interface StepperProps {
  value: number;
  onChange: (value: number) => void;
  min?: number;
  max?: number;
  disabled?: boolean;
  size?: 'md' | 'sm';
}

/** Stepper do Figma: caixa cinza-clara com − e + nas pontas e valor central. */
export function Stepper({ value, onChange, min = 0, max = 99, disabled, size = 'md' }: StepperProps) {
  const canDec = !disabled && value > min;
  const canInc = !disabled && value < max;
  const h = size === 'sm' ? 28 : 34;
  return (
    <View style={[styles.root, { height: h }, disabled && styles.disabled]}>
      <Pressable
        onPress={() => canDec && onChange(value - 1)}
        disabled={!canDec}
        hitSlop={8}
        accessibilityRole="button"
        accessibilityLabel="Diminuir"
        style={({ pressed }) => [styles.btn, { width: h }, !canDec && styles.btnOff, pressed && styles.pressed]}
      >
        <Ionicons name="remove" size={16} color={colors.text} />
      </Pressable>
      <View style={styles.valueWrap}>
        <Text variant="bodyMedium" style={styles.value} accessibilityLiveRegion="polite">
          {value}
        </Text>
      </View>
      <Pressable
        onPress={() => canInc && onChange(value + 1)}
        disabled={!canInc}
        hitSlop={8}
        accessibilityRole="button"
        accessibilityLabel="Aumentar"
        style={({ pressed }) => [styles.btn, { width: h }, !canInc && styles.btnOff, pressed && styles.pressed]}
      >
        <Ionicons name="add" size={16} color={colors.text} />
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.muted,
    borderRadius: radius.xs,
    overflow: 'hidden',
  },
  disabled: { opacity: 0.5 },
  btn: { height: '100%', alignItems: 'center', justifyContent: 'center', backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.borderStrong, borderRadius: radius.xs },
  btnOff: { opacity: 0.4 },
  pressed: { opacity: 0.6 },
  valueWrap: { minWidth: 40, paddingHorizontal: space(1), alignItems: 'center' },
  value: { textAlign: 'center' },
});
