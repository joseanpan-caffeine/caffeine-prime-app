import { Pressable, StyleSheet, View } from 'react-native';
import type { ReasonOption } from '@/api/contracts';
import { Card, RadioRow, Text } from '@/components';
import { colors, radius, space } from '@/theme';

interface ReasonPickerProps {
  reasons: ReasonOption[];
  value: string | null;
  onChange: (code: string) => void;
  followUpAnswer: string | null;
  onFollowUp: (answer: string) => void;
}

/** Lista de motivos (radio) com pergunta de follow-up opcional. */
export function ReasonPicker({ reasons, value, onChange, followUpAnswer, onFollowUp }: ReasonPickerProps) {
  const selected = reasons.find((r) => r.code === value);
  return (
    <View>
      <View>
        {reasons.map((r) => (
          <RadioRow key={r.code} boxed label={r.label} selected={r.code === value} onPress={() => onChange(r.code)} />
        ))}
      </View>
      {selected?.followUp ? (
        <Card title={selected.followUp.question} padded>
          <View style={styles.chips}>
            {selected.followUp.options.map((opt) => {
              const active = opt === followUpAnswer;
              return (
                <Pressable key={opt} onPress={() => onFollowUp(opt)} accessibilityRole="button" accessibilityState={{ selected: active }} style={[styles.chip, active && styles.chipOn]}>
                  <Text variant="small" tone={active ? 'onPrimary' : 'default'}>
                    {opt}
                  </Text>
                </Pressable>
              );
            })}
          </View>
        </Card>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  chips: { flexDirection: 'row', flexWrap: 'wrap', gap: space(2) },
  chip: { paddingHorizontal: space(3), paddingVertical: space(2), borderRadius: radius.pill, borderWidth: 1, borderColor: colors.borderStrong, backgroundColor: colors.subtle },
  chipOn: { backgroundColor: colors.primary, borderColor: colors.primary },
});
