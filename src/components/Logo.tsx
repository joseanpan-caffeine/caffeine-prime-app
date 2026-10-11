import { StyleSheet, View, type ViewStyle } from 'react-native';
import { colors, font, logoFont } from '@/theme';
import { Text } from './Text';

interface LogoProps {
  size?: 'sm' | 'md' | 'lg';
  /** Cor do texto (padrão escuro; use branco sobre fundo escuro). */
  color?: string;
  style?: ViewStyle;
}

/**
 * Logo "CAFFEINE ARMY / PRIME" renderizada como texto em dois níveis
 * (CAFFEINE ARMY pequeno em caixa alta + PRIME grande itálico-pesado)
 * até recebermos o SVG oficial.
 */
export function Logo({ size = 'md', color = colors.text, style }: LogoProps) {
  const scale = size === 'sm' ? 0.8 : size === 'lg' ? 1.6 : 1;
  return (
    <View style={[styles.root, style]} accessibilityRole="header" accessibilityLabel="Caffeine Army Prime">
      <Text style={[font('heading', '700'), { fontSize: 8 * scale, lineHeight: 10 * scale, letterSpacing: 1.6 * scale, color }]}>CAFFEINE ARMY</Text>
      <Text style={[logoFont(), { fontSize: 22 * scale, lineHeight: 24 * scale, letterSpacing: -0.6 * scale, color, marginTop: -1 }]}>PRIME</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { alignItems: 'center' },
});
