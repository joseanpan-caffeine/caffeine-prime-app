import { StyleSheet, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, shadows, space } from '@/theme';
import { Text } from './Text';

export interface TimelineStep {
  key: string;
  label: string;
  sublabel?: string;
  done?: boolean;
}

interface CommitmentTimelineProps {
  steps: TimelineStep[];
}

/** Timeline de fidelidade: 4 pontos verdes com check ligados por linha ("Próxima caixa 17 de Julho / Mês 2 / …"). */
export function CommitmentTimeline({ steps }: CommitmentTimelineProps) {
  return (
    <View style={[styles.card, shadows.card]}>
      <View style={styles.row}>
        {steps.map((s, i) => (
          <View key={s.key} style={styles.step}>
            <View style={styles.dotRow}>
              <View style={[styles.line, i === 0 && styles.lineHidden]} />
              <View style={[styles.dot, s.done === false && styles.dotOff]}>
                <Ionicons name="checkmark" size={12} color="#FFFFFF" />
              </View>
              <View style={[styles.line, i === steps.length - 1 && styles.lineHidden]} />
            </View>
            <Text variant="caption" tone="secondary" center numberOfLines={1}>
              {s.label}
            </Text>
            {s.sublabel ? (
              <Text variant="captionStrong" center numberOfLines={1}>
                {s.sublabel}
              </Text>
            ) : null}
          </View>
        ))}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  card: { backgroundColor: colors.surface, borderRadius: radius.md, paddingVertical: space(4), paddingHorizontal: space(2), marginBottom: space(3) },
  row: { flexDirection: 'row' },
  step: { flex: 1, alignItems: 'center', gap: 2 },
  dotRow: { flexDirection: 'row', alignItems: 'center', alignSelf: 'stretch', marginBottom: space(2) },
  line: { flex: 1, height: 1, backgroundColor: colors.borderStrong },
  lineHidden: { backgroundColor: 'transparent' },
  dot: { width: 20, height: 20, borderRadius: 10, backgroundColor: colors.success, alignItems: 'center', justifyContent: 'center' },
  dotOff: { backgroundColor: colors.borderStrong },
});
