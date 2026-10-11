import { StyleSheet, View, type ImageStyle, type ViewStyle } from 'react-native';
import { Image } from 'expo-image';
import { getCardBrandLogo, PIX_LOGO } from '@/lib/brandLogos';
import { colors, radius } from '@/theme';
import { Text } from './Text';

interface CardBrandLogoProps {
  /** Nome da bandeira como vem da API (ex.: "Visa", "mastercard", "American Express"). */
  brand?: string | null;
  width?: number;
  height?: number;
  style?: ImageStyle & ViewStyle;
}

/**
 * Logo da bandeira do cartão (SVG em assets/brand) em ~32×20. Bandeira desconhecida →
 * badge de texto com o nome abreviado, para nunca ficar um espaço vazio.
 */
export function CardBrandLogo({ brand, width = 32, height = 20, style }: CardBrandLogoProps) {
  const logo = getCardBrandLogo(brand);
  if (logo) {
    return <Image source={logo} style={[{ width, height }, style]} contentFit="contain" accessibilityLabel={brand ?? 'Cartão'} />;
  }
  const label = (brand ?? 'Cartão').trim().slice(0, 6).toUpperCase() || 'CARTÃO';
  return (
    <View style={[styles.badge, { minWidth: width, height }, style]} accessibilityLabel={brand ?? 'Cartão'}>
      <Text variant="captionStrong" tone="secondary" numberOfLines={1} style={styles.badgeText}>
        {label}
      </Text>
    </View>
  );
}

interface PixLogoProps {
  size?: number;
  /** Tinge o glifo (o SVG oficial é escuro; use branco em fundos escuros). */
  color?: string;
  style?: ImageStyle;
}

/** Logo do PIX (assets/brand/pix.svg). */
export function PixLogo({ size = 20, color, style }: PixLogoProps) {
  return <Image source={PIX_LOGO} style={[{ width: size, height: size }, style]} contentFit="contain" tintColor={color} accessibilityLabel="PIX" />;
}

const styles = StyleSheet.create({
  badge: { paddingHorizontal: 4, borderRadius: radius.xs, backgroundColor: colors.muted, alignItems: 'center', justifyContent: 'center' },
  badgeText: { fontSize: 9, lineHeight: 11 },
});
