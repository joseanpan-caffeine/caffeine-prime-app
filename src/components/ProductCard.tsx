import { Pressable, StyleSheet, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, shadows, space } from '@/theme';
import { Badge } from './Badge';
import { Button } from './Button';
import { ProductImage } from './ProductImage';
import { Text } from './Text';

export interface ProductCardProps {
  title: string;
  flavor?: string;
  spec?: string;
  imageUrl?: string;
  /** Preço cheio ("compra única"), riscado. */
  fullPriceLabel?: string;
  priceLabel: string;
  discountPercentage?: number;
  exclusive?: boolean;
  launch?: boolean;
  outOfStock?: boolean;
  onAdd?: () => void;
  onBuy?: () => void;
  width?: number;
}

/**
 * Card de produto do carrossel "Complete sua rotina com itens exclusivos":
 * badge EXCLUSIVO PRIME, imagem, nome bold, sabor, peso/doses, preço cheio riscado,
 * preço Prime + badge "15% OFF" verde, "Adicionar à caixa" primário + "Comprar" secundário.
 */
export function ProductCard({ title, flavor, spec, imageUrl, fullPriceLabel, priceLabel, discountPercentage, exclusive = true, launch, outOfStock, onAdd, onBuy, width = 150 }: ProductCardProps) {
  return (
    <View style={[styles.card, shadows.card, { width }]}>
      <View style={styles.badges}>
        {exclusive ? <Badge label="Exclusivo Prime" tone="exclusive" size="sm" /> : null}
        {launch ? <Badge label="Lançamento" tone="launch" size="sm" /> : null}
      </View>
      <View style={styles.imageWrap}>
        <ProductImage uri={imageUrl} title={title} width={width - space(6)} height={96} bg={colors.subtle} />
      </View>
      <Text variant="bodyStrong" numberOfLines={2} style={styles.title}>
        {title}
      </Text>
      <Text variant="caption" tone="secondary" numberOfLines={1}>
        {flavor ?? ' '}
      </Text>
      <Text variant="caption" tone="secondary" numberOfLines={1}>
        {spec ?? ' '}
      </Text>
      <View style={styles.prices}>
        {fullPriceLabel ? (
          <Text variant="caption" tone="dim" numberOfLines={1}>
            <Text variant="caption" tone="dim" style={styles.strike}>
              {fullPriceLabel}
            </Text>{' '}
            compra única
          </Text>
        ) : null}
        <View style={styles.priceRow}>
          <Text variant="bodyStrong" numberOfLines={1}>
            {priceLabel}
          </Text>
          {discountPercentage ? <Badge label={`${discountPercentage}% OFF`} tone="off" size="sm" /> : null}
        </View>
      </View>
      <View style={styles.actions}>
        {onAdd ? <Button title="Adicionar à caixa" size="sm" onPress={onAdd} disabled={outOfStock} /> : null}
        {onBuy ? <Button title="Comprar" size="sm" variant="secondary" onPress={onBuy} disabled={outOfStock} /> : null}
      </View>
    </View>
  );
}

interface ProductTileProps {
  title: string;
  flavor?: string;
  imageUrl?: string;
  priceLabel: string;
  fullPriceLabel?: string;
  discountPercentage?: number;
  exclusive?: boolean;
  outOfStock?: boolean;
  onAdd: () => void;
  width?: number;
}

/** Tile compacto (Figma "alerts" rodapé): imagem com botão "+" redondo, nome, preço, riscado + badge OFF. */
export function ProductTile({ title, flavor, imageUrl, priceLabel, fullPriceLabel, discountPercentage, exclusive, outOfStock, onAdd, width = 150 }: ProductTileProps) {
  return (
    <View style={[styles.tile, { width }]}>
      <View style={styles.tileImage}>
        <ProductImage uri={imageUrl} title={title} width={width} height={110} radiusSize={radius.sm} bg={colors.muted} desaturated={outOfStock} />
        {exclusive ? (
          <View style={styles.crown}>
            <Ionicons name="star" size={12} color={colors.brandDark} />
          </View>
        ) : null}
        <Pressable onPress={onAdd} disabled={outOfStock} accessibilityRole="button" accessibilityLabel={`Adicionar ${title}`} style={({ pressed }) => [styles.plus, pressed && styles.pressed, outOfStock && styles.plusOff]}>
          <Ionicons name="add" size={22} color={colors.text} />
        </Pressable>
      </View>
      <Text variant="bodyStrong" numberOfLines={1}>
        {title}
      </Text>
      <Text variant="caption" tone="secondary" numberOfLines={1}>
        {outOfStock ? 'Esgotado' : (flavor ?? ' ')}
      </Text>
      <Text variant="bodyStrong" style={styles.tilePrice}>
        {priceLabel}
      </Text>
      <View style={styles.priceRow}>
        {fullPriceLabel ? (
          <Text variant="caption" tone="dim" style={styles.strike}>
            {fullPriceLabel}
          </Text>
        ) : null}
        {discountPercentage ? <Badge label={`${discountPercentage}% OFF`} tone="off" size="sm" /> : null}
      </View>
      {exclusive ? (
        <Text variant="caption" tone="dim">
          Exclusivo Prime
        </Text>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  card: { backgroundColor: colors.surface, borderRadius: radius.md, padding: space(3), gap: 2 },
  badges: { flexDirection: 'row', gap: space(1), minHeight: 20, alignItems: 'center' },
  imageWrap: { alignItems: 'center', marginVertical: space(2) },
  title: { marginTop: space(1), minHeight: 38 },
  prices: { marginTop: space(2), gap: 2 },
  strike: { textDecorationLine: 'line-through' },
  priceRow: { flexDirection: 'row', alignItems: 'center', gap: space(1.5) },
  actions: { gap: space(2), marginTop: space(3) },
  tile: { gap: 2 },
  tileImage: { position: 'relative', marginBottom: space(2) },
  crown: { position: 'absolute', top: 8, left: 8, width: 22, height: 22, borderRadius: radius.xs, backgroundColor: colors.primaryStrong, alignItems: 'center', justifyContent: 'center' },
  plus: { position: 'absolute', right: 8, bottom: 8, width: 36, height: 36, borderRadius: 18, backgroundColor: colors.surface, alignItems: 'center', justifyContent: 'center', ...shadows.card },
  plusOff: { opacity: 0.4 },
  pressed: { opacity: 0.7 },
  tilePrice: { marginTop: space(1) },
});
