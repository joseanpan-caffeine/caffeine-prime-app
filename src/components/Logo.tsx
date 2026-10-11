import { useState } from 'react';
import { StyleSheet, View, type ViewStyle } from 'react-native';
import { Image } from 'expo-image';
import { colors, font, logoFont } from '@/theme';
import { Text } from './Text';

/** Proporção do lockup horizontal oficial (viewBox 841.5 × 55.59). */
const LOGO_RATIO = 841.5 / 55.59;

const LOGO_DARK = require('../../assets/brand/caffeine-prime.svg');
const LOGO_WHITE = require('../../assets/brand/caffeine-prime-white.svg');

interface LogoProps {
  /** `dark` (texto escuro, fundos claros) ou `white` (fundos escuros). */
  variant?: 'dark' | 'white';
  /** Largura em pontos; a altura segue a proporção do SVG. */
  width?: number;
  style?: ViewStyle;
}

/**
 * Logo oficial "CAFFEINE ARMY prime" (SVG horizontal) renderizada via expo-image.
 * Se o SVG falhar ao carregar, cai para o `TextLogo` tipográfico.
 */
export function Logo({ variant = 'dark', width = 170, style }: LogoProps) {
  const [failed, setFailed] = useState(false);
  const height = Math.round(width / LOGO_RATIO);
  if (failed) {
    return <TextLogo color={variant === 'white' ? '#FFFFFF' : colors.text} scale={width / 170} style={style} />;
  }
  return (
    <View style={[{ width, height }, style]} accessibilityRole="header" accessibilityLabel="Caffeine Army Prime">
      <Image source={variant === 'white' ? LOGO_WHITE : LOGO_DARK} style={StyleSheet.absoluteFill} contentFit="contain" onError={() => setFailed(true)} />
    </View>
  );
}

interface TextLogoProps {
  color?: string;
  scale?: number;
  style?: ViewStyle;
}

/**
 * Fallback tipográfico ("CAFFEINE ARMY" pequeno + "PRIME" grande), usado apenas
 * quando o SVG oficial não pode ser carregado.
 */
export function TextLogo({ color = colors.text, scale = 1, style }: TextLogoProps) {
  return (
    <View style={[styles.textRoot, style]} accessibilityRole="header" accessibilityLabel="Caffeine Army Prime">
      <Text style={[font('heading', '700'), { fontSize: 8 * scale, lineHeight: 10 * scale, letterSpacing: 1.6 * scale, color }]}>CAFFEINE ARMY</Text>
      <Text style={[logoFont(), { fontSize: 22 * scale, lineHeight: 24 * scale, letterSpacing: -0.6 * scale, color, marginTop: -1 }]}>PRIME</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  textRoot: { alignItems: 'center' },
});
