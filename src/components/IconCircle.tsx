import { useState, type ReactNode } from 'react';
import { StyleSheet, View, type ViewStyle } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Image } from 'expo-image';
import { colors, radius } from '@/theme';
import { Text } from './Text';

const CAFFEINE_X = require('../../assets/brand/caffeine-x.svg');

export type IoniconName = keyof typeof Ionicons.glyphMap;

interface IconCircleProps {
  /** Ícone Ionicons; ignorado quando `children` é passado. */
  icon?: IoniconName;
  children?: ReactNode;
  size?: number;
  iconSize?: number;
  bg?: string;
  color?: string;
  style?: ViewStyle;
}

/** Círculo de ícone (ações rápidas, listas): bg #F8F9FA, ícone #495057. */
export function IconCircle({ icon, children, size = 56, iconSize, bg = colors.subtle, color = colors.textSecondary, style }: IconCircleProps) {
  return (
    <View style={[styles.circle, { width: size, height: size, backgroundColor: bg }, style]}>
      {children ?? (icon ? <Ionicons name={icon} size={iconSize ?? Math.round(size * 0.42)} color={color} /> : null)}
    </View>
  );
}

/**
 * Ícone oficial do Caffeine Army X (SVG em assets/brand) tingido com `color` (padrão roxo).
 * Se o SVG falhar, cai para o glifo tipográfico "X".
 */
export function CaffeineXIcon({ size = 22, color = colors.purple }: { size?: number; color?: string }) {
  const [failed, setFailed] = useState(false);
  if (failed) {
    return (
      <Text style={{ fontSize: size, lineHeight: size + 2, color, fontWeight: '900', fontStyle: 'italic', letterSpacing: -1 }} accessibilityLabel="Caffeine Army X">
        X
      </Text>
    );
  }
  return <Image source={CAFFEINE_X} style={{ width: size, height: size }} contentFit="contain" tintColor={color} onError={() => setFailed(true)} accessibilityLabel="Caffeine Army X" />;
}

const styles = StyleSheet.create({
  circle: { borderRadius: radius.pill, alignItems: 'center', justifyContent: 'center' },
});
