import { StyleSheet, View } from 'react-native';
import { colors, radius, space } from '@/theme';
import { Button } from './Button';
import { Text } from './Text';

interface EmptyStateProps {
  icon?: string;
  title: string;
  description?: string;
  actionLabel?: string;
  onAction?: () => void;
  secondaryLabel?: string;
  onSecondary?: () => void;
}

export function EmptyState({ icon = '☕', title, description, actionLabel, onAction, secondaryLabel, onSecondary }: EmptyStateProps) {
  return (
    <View style={styles.root}>
      <View style={styles.iconWrap}>
        <Text style={styles.icon}>{icon}</Text>
      </View>
      <Text variant="heading" center>
        {title}
      </Text>
      {description ? (
        <Text variant="small" tone="muted" center style={styles.description}>
          {description}
        </Text>
      ) : null}
      {actionLabel && onAction ? <Button title={actionLabel} onPress={onAction} style={styles.action} /> : null}
      {secondaryLabel && onSecondary ? <Button title={secondaryLabel} onPress={onSecondary} variant="ghost" /> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  root: { alignItems: 'center', paddingVertical: space(10), paddingHorizontal: space(6), gap: space(2) },
  iconWrap: {
    width: 64,
    height: 64,
    borderRadius: radius.pill,
    backgroundColor: colors.surfaceElevated,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: space(2),
  },
  icon: { fontSize: 28 },
  description: { maxWidth: 300 },
  action: { marginTop: space(4), minWidth: 200 },
});
