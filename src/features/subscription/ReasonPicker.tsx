import { Pressable, StyleSheet, View } from 'react-native';
import type { ReasonOption } from '@/api/contracts';
import { Card, Text } from '@/components';
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
      <Card padded={false}>
        {reasons.map((r, idx) => {
          const active = r.code === value;
          return (
            <Pressable
              key={r.code}
              onPress={() => onChange(r.code)}
              accessibilityRole="radio"
              accessibilityState={{ selected: active }}
              style={[styles.row, idx < reasons.length - 1 && styles.border]}
            >
              <View style={[styles.radio, active && styles.radioOn]} />
              <Text variant={active ? 'bodyStrong' : 'body'} style={styles.flex1}>
                {r.label}
              </Text>
            </Pressable>
          );
        })}
      </Card>
      {selected?.followUp ? (
        <Card title={selected.followUp.question} padded>
          <View style={styles.chips}>
            {selected.followUp.options.map((opt) => {
              const active = opt === followUpAnswer;
              return (
                <Pressable key={opt} onPress={() => onFollowUp(opt)} accessibilityRole="button" accessibilityState={{ selected: active }} style={[styles.chip, active && styles.chipOn]}>
                  <Text variant="small" tone={active ? 'onAccent' : 'default'}>
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
  flex1: { flex: 1 },
  row: { flexDirection: 'row', alignItems: 'center', gap: space(3), padding: space(4) },
  border: { borderBottomWidth: StyleSheet.hairlineWidth, borderBottomColor: colors.border },
  radio: { width: 20, height: 20, borderRadius: 10, borderWidth: 2, borderColor: colors.borderStrong },
  radioOn: { borderColor: colors.accent, backgroundColor: colors.accent },
  chips: { flexDirection: 'row', flexWrap: 'wrap', gap: space(2) },
  chip: { paddingHorizontal: space(3), paddingVertical: space(2), borderRadius: radius.pill, borderWidth: 1, borderColor: colors.borderStrong, backgroundColor: colors.surfaceElevated },
  chipOn: { backgroundColor: colors.accent, borderColor: colors.accent },
});
