import { useMemo, useState } from 'react';
import { StyleSheet, View, type ViewStyle } from 'react-native';
import { Image } from 'expo-image';
import { getLocalProductImage } from '@/lib/productImages';
import { colors, radius } from '@/theme';
import { Text } from './Text';

interface ProductImageProps {
  uri?: string | null;
  /** Handle do produto/sabor: escolhe a imagem local quando a remota falta ou falha. */
  handle?: string;
  /** Usado para a inicial do placeholder e como pista para a imagem local. */
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
 * Imagem de produto. Ordem de resolução:
 * 1. `imageUrl` da API (se existir e não tiver falhado);
 * 2. imagem empacotada no app, por `handle`/título (`src/lib/productImages.ts`);
 * 3. tile cinza-claro com a inicial do nome. Nunca deixa imagem quebrada.
 */
export function ProductImage({ uri, handle, title, size = 56, width, height, radiusSize = radius.sm, bg = colors.muted, desaturated, style }: ProductImageProps) {
  // Guarda a URL que falhou: uma nova URL volta a ser tentada automaticamente.
  const [failedUri, setFailedUri] = useState<string | null>(null);
  const [localFailed, setLocalFailed] = useState(false);
  const remoteFailed = !!uri && failedUri === uri;

  const w = width ?? size;
  const h = height ?? size;
  const local = useMemo(() => getLocalProductImage(handle, title), [handle, title]);
  const source = uri && !remoteFailed ? { uri } : local && !localFailed ? local : undefined;
  const initial = (title?.trim()?.[0] ?? '').toUpperCase();

  return (
    <View style={[styles.tile, { width: w, height: h, borderRadius: radiusSize, backgroundColor: bg }, desaturated && styles.desaturated, style]}>
      {source ? (
        <Image
          source={source}
          style={StyleSheet.absoluteFill}
          contentFit="contain"
          transition={150}
          onError={() => (uri && !remoteFailed ? setFailedUri(uri) : setLocalFailed(true))}
          accessibilityLabel={title}
        />
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
