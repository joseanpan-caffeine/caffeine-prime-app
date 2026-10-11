import { useEffect, useState } from 'react';
import { Animated, StyleSheet, View, type DimensionValue, type ViewStyle } from 'react-native';
import { colors, radius, space } from '@/theme';

interface SkeletonProps {
  width?: DimensionValue;
  height?: number;
  round?: boolean;
  style?: ViewStyle;
}

export function Skeleton({ width = '100%', height = 16, round, style }: SkeletonProps) {
  const [opacity] = useState(() => new Animated.Value(0.5));
  useEffect(() => {
    const loop = Animated.loop(
      Animated.sequence([
        Animated.timing(opacity, { toValue: 1, duration: 700, useNativeDriver: true }),
        Animated.timing(opacity, { toValue: 0.5, duration: 700, useNativeDriver: true }),
      ]),
    );
    loop.start();
    return () => loop.stop();
  }, [opacity]);
  return (
    <Animated.View
      style={[styles.base, { width, height, borderRadius: round ? height / 2 : radius.sm, opacity }, style]}
    />
  );
}

/** Esqueleto de um card padrão. */
export function SkeletonCard({ lines = 3 }: { lines?: number }) {
  return (
    <View style={styles.card}>
      <Skeleton width="50%" height={20} />
      {Array.from({ length: lines }).map((_, i) => (
        <Skeleton key={i} width={i === lines - 1 ? '60%' : '90%'} />
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  base: { backgroundColor: colors.skeleton },
  card: {
    backgroundColor: colors.surface,
    borderRadius: radius.lg,
    padding: space(4),
    gap: space(3),
    marginBottom: space(3),
    borderWidth: 1,
    borderColor: colors.border,
  },
});
