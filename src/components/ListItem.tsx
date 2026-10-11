import type { ReactNode } from 'react';
import { Pressable, StyleSheet, View, type ViewStyle } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, space } from '@/theme';
import { Text } from './Text';

interface ListItemProps {
  title: string;
  subtitle?: string;
  left?: ReactNode;
  right?: ReactNode;
  onPress?: () => void;
  chevron?: boolean;
  danger?: boolean;
  style?: ViewStyle;
  last?: boolean;
}

export function ListItem({ title, subtitle, left, right, onPress, chevron, danger, style, last }: ListItemProps) {
  const inner = (
    <View style={[styles.row, !last && styles.border, style]}>
      {left ? <View style={styles.left}>{left}</View> : null}
      <View style={styles.text}>
        <Text variant="bodyStrong" tone={danger ? 'danger' : 'default'} numberOfLines={2}>
          {title}
        </Text>
        {subtitle ? (
          <Text variant="small" tone="muted" numberOfLines={2}>
            {subtitle}
          </Text>
        ) : null}
      </View>
      {right ? <View style={styles.right}>{right}</View> : null}
      {chevron ?? !!onPress ? (
        <Ionicons name="chevron-forward" size={18} color={colors.text} style={styles.chevron} />
      ) : null}
    </View>
  );
  if (!onPress) return inner;
  return (
    <Pressable onPress={onPress} accessibilityRole="button" style={({ pressed }) => pressed && styles.pressed}>
      {inner}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', alignItems: 'center', paddingVertical: space(3), gap: space(3) },
  border: { borderBottomWidth: 1, borderBottomColor: colors.border },
  left: { width: 28, alignItems: 'center' },
  text: { flex: 1, gap: 2 },
  right: { alignItems: 'flex-end' },
  chevron: { marginLeft: space(1) },
  pressed: { opacity: 0.7 },
});
