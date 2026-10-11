import { Pressable, StyleSheet, View } from 'react-native';
import { colors, radius, space } from '@/theme';
import { Text } from './Text';

interface StepperProps {
  value: number;
  onChange: (value: number) => void;
  min?: number;
  max?: number;
  disabled?: boolean;
}

export function Stepper({ value, onChange, min = 0, max = 99, disabled }: StepperProps) {
  const canDec = !disabled && value > min;
  const canInc = !disabled && value < max;
  return (
    <View style={[styles.root, disabled && styles.disabled]}>
      <Pressable
        onPress={() => canDec && onChange(value - 1)}
        disabled={!canDec}
        hitSlop={8}
        accessibilityRole="button"
        accessibilityLabel="Diminuir"
        style={({ pressed }) => [styles.btn, !canDec && styles.btnOff, pressed && styles.pressed]}
      >
        <Text variant="heading" tone={canDec ? 'accent' : 'dim'}>
          −
        </Text>
      </Pressable>
      <Text variant="bodyStrong" style={styles.value} accessibilityLiveRegion="polite">
        {value}
      </Text>
      <Pressable
        onPress={() => canInc && onChange(value + 1)}
        disabled={!canInc}
        hitSlop={8}
        accessibilityRole="button"
        accessibilityLabel="Aumentar"
        style={({ pressed }) => [styles.btn, !canInc && styles.btnOff, pressed && styles.pressed]}
      >
        <Text variant="heading" tone={canInc ? 'accent' : 'dim'}>
          +
        </Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.surfaceElevated,
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: colors.borderStrong,
  },
  disabled: { opacity: 0.5 },
  btn: { width: 36, height: 36, alignItems: 'center', justifyContent: 'center' },
  btnOff: { opacity: 0.4 },
  pressed: { opacity: 0.6 },
  value: { minWidth: 28, textAlign: 'center', paddingHorizontal: space(1) },
});
