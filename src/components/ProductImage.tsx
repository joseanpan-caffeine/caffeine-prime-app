import { useState } from 'react';
import { StyleSheet, View, type ViewStyle } from 'react-native';
import { Image } from 'expo-image';
import { colors, radius } from '@/theme';
import { Text } from './Text';

interface ProductImageProps {
  uri?: string | null;
  /** Usado para a inicial do placeholder. */
  title?: string;
  size?: number;
  width?: number;
  height?: number;
  radiusSize?: number;
  /** Fundo do tile (padrão cinza-claro). */
  bg?: string;
  /** Imagem acinzentada (variante "pagamento pendente"). */
  desaturated?: boolean;
  style?: ViewStyle;
}

/**
 * Imagem de produto: usa `imageUrl` da API; sem imagem (ou com erro de carregamento)
 * mostra um tile cinza-claro com a inicial do nome. Nunca deixa imagem quebrada.
 */
export function ProductImage({ uri, title, size = 56, width, height, radiusSize = radius.sm, bg = colors.muted, desaturated, style }: ProductImageProps) {
  const [failed, setFailed] = useState(false);
  const w = width ?? size;
  const h = height ?? size;
  const showImage = !!uri && !failed;
  const initial = (title?.trim()?.[0] ?? '').toUpperCase();
  return (
    <View style={[styles.tile, { width: w, height: h, borderRadius: radiusSize, backgroundColor: bg }, desaturated && styles.desaturated, style]}>
      {showImage ? (
        <Image source={{ uri: uri! }} style={StyleSheet.absoluteFill} contentFit="contain" transition={150} onError={() => setFailed(true)} accessibilityLabel={title} />
      ) : (
        <Text variant="heading" tone="dim" style={{ fontSize: Math.max(12, Math.round(Math.min(w, h) * 0.34)), lineHeight: Math.round(Math.min(w, h) * 0.44) }}>
          {initial}
        </Text>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  tile: { alignItems: 'center', justifyContent: 'center', overflow: 'hidden' },
  desaturated: { opacity: 0.55 },
});
