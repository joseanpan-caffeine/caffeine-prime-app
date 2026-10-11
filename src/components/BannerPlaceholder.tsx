import { Pressable, StyleSheet, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Image } from 'expo-image';
import { colors, radius, space } from '@/theme';
import { Text } from './Text';

interface BannerPlaceholderProps {
  imageUrl?: string;
  title?: string;
  subtitle?: string;
  onPress?: () => void;
  height?: number;
  /** Quantidade de pontos do indicador (padrão 2). */
  dots?: number;
  activeDot?: number;
}

/** Bloco de banner do Figma: retângulo cinza arredondado com ícone de imagem e pontos. */
export function BannerPlaceholder({ imageUrl, title, subtitle, onPress, height = 150, dots = 2, activeDot = 0 }: BannerPlaceholderProps) {
  return (
    <View style={styles.root}>
      <Pressable onPress={onPress} disabled={!onPress} accessibilityRole={onPress ? 'button' : undefined} style={({ pressed }) => [styles.block, { height }, pressed && styles.pressed]}>
        {imageUrl ? <Image source={{ uri: imageUrl }} style={StyleSheet.absoluteFill} contentFit="cover" /> : <Ionicons name="image-outline" size={64} color={colors.textMuted} />}
        {title ? (
          <View style={styles.caption}>
            <Text variant="bodyStrong" tone="onDark" numberOfLines={1}>
              {title}
            </Text>
            {subtitle ? (
              <Text variant="caption" tone="onDark" numberOfLines={1}>
                {subtitle}
              </Text>
            ) : null}
          </View>
        ) : null}
      </Pressable>
      <View style={styles.dots}>
        {Array.from({ length: dots }).map((_, i) => (
          <View key={i} style={[styles.dot, i === activeDot && styles.dotOn]} />
        ))}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { marginBottom: space(3), gap: space(2) },
  block: { borderRadius: radius.md, backgroundColor: colors.borderStrong, alignItems: 'center', justifyContent: 'center', overflow: 'hidden' },
  pressed: { opacity: 0.85 },
  caption: { position: 'absolute', left: 0, right: 0, bottom: 0, padding: space(3), backgroundColor: 'rgba(38,15,15,0.6)' },
  dots: { flexDirection: 'row', justifyContent: 'center', gap: 6 },
  dot: { width: 8, height: 8, borderRadius: 4, backgroundColor: colors.borderStrong },
  dotOn: { width: 22, backgroundColor: colors.text },
});
