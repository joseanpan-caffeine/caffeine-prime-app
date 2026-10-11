import type { ReactNode } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, shadows, space } from '@/theme';
import { CaffeineXIcon } from './IconCircle';
import { Text } from './Text';

interface DuoCardsProps {
  points: number;
  pointsLabel?: string;
  partnersLabel?: ReactNode;
  onPoints?: () => void;
  onClub?: () => void;
}

/** Dupla "Caffeine Army X" (roxo) + "Clube de Vantagens" (dourado). */
export function DuoCards({ points, pointsLabel, partnersLabel, onPoints, onClub }: DuoCardsProps) {
  return (
    <View style={styles.row}>
      <Pressable onPress={onPoints} accessibilityRole="button" style={({ pressed }) => [styles.card, shadows.card, pressed && styles.pressed]}>
        <View style={styles.icon}>
          <CaffeineXIcon size={22} />
        </View>
        <Text variant="bodyStrong">Caffeine Army X</Text>
        <Text variant="small" tone="purple">
          {pointsLabel ?? 'Você possui'}{' '}
          <Text variant="smallStrong" tone="purple">
            {points.toLocaleString('pt-BR')} pontos
          </Text>
        </Text>
      </Pressable>
      <Pressable onPress={onClub} accessibilityRole="button" style={({ pressed }) => [styles.card, shadows.card, pressed && styles.pressed]}>
        <View style={styles.icon}>
          <Ionicons name="bag-handle-outline" size={22} color={colors.gold} />
        </View>
        <Text variant="bodyStrong">Clube de Vantagens</Text>
        <Text variant="small" tone="secondary">
          {partnersLabel ?? (
            <>
              Até <Text variant="smallStrong">20% OFF</Text> em parceiros
            </>
          )}
        </Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', gap: space(3), marginBottom: space(3) },
  card: { flex: 1, backgroundColor: colors.surface, borderRadius: radius.md, padding: space(4), gap: 2 },
  icon: { height: 26, justifyContent: 'center', marginBottom: space(4) },
  pressed: { opacity: 0.85 },
});
