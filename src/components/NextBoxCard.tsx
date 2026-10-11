import { useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, shadows, space } from '@/theme';
import { Badge } from './Badge';
import { Button } from './Button';
import { ProductImage } from './ProductImage';
import { Text } from './Text';

export interface NextBoxItem {
  id: string;
  title: string;
  subtitle?: string;
  imageUrl?: string;
  quantity: number;
}

export interface NextBoxGift {
  id: string;
  title: string;
  imageUrl?: string;
}

interface NextBoxCardProps {
  paymentDateLabel: string;
  totalLabel: string;
  items: NextBoxItem[];
  gifts?: NextBoxGift[];
  /** Data limite de alteração ("14/07"). */
  editUntilLabel?: string;
  canEdit?: boolean;
  onEdit?: () => void;
  onAddItems?: () => void;
  onEditItem?: (item: NextBoxItem) => void;
  /** Variante clara/desaturada para "Pagamento pendente". */
  pendingPayment?: boolean;
  /** Ciclo futuro: só visualização (sem lápis / adicionar). */
  readOnly?: boolean;
}

/**
 * Card "próxima caixa" (Figma Next Box): escuro #260F0F com data de pagamento,
 * valor total, grade de produtos com badge de quantidade, bloco "+ Adicionar itens",
 * brindes, botão "Editar caixa" dourado e rodapé "ⓘ Você pode alterar sua caixa até…".
 */
export function NextBoxCard({
  paymentDateLabel,
  totalLabel,
  items,
  gifts = [],
  editUntilLabel,
  canEdit = true,
  onEdit,
  onAddItems,
  onEditItem,
  pendingPayment = false,
  readOnly = false,
}: NextBoxCardProps) {
  const [giftsOpen, setGiftsOpen] = useState(true);
  const light = pendingPayment;
  const textTone = light ? 'dim' : 'onDark';
  const mutedTone = light ? 'dim' : 'onDarkMuted';
  const interactive = !readOnly && !pendingPayment;

  return (
    <View style={[styles.card, light ? styles.cardLight : styles.cardDark, light && shadows.card]}>
      <View style={styles.top}>
        <View style={styles.topCol}>
          <Text variant="caption" tone={mutedTone}>
            Data de pagamento
          </Text>
          <Text variant="bodyStrong" tone={textTone}>
            {paymentDateLabel}
          </Text>
        </View>
        <View style={styles.topCol}>
          <Text variant="caption" tone={mutedTone}>
            Valor total
          </Text>
          <Text variant="bodyStrong" tone={textTone}>
            {totalLabel}
          </Text>
        </View>
        {pendingPayment ? <Badge label="Pagamento pendente" tone="pending" size="sm" /> : null}
      </View>

      <View style={styles.grid}>
        {items.map((item) => (
          <Pressable
            key={item.id}
            onPress={interactive && onEditItem ? () => onEditItem(item) : undefined}
            disabled={!interactive || !onEditItem}
            accessibilityRole={interactive && onEditItem ? 'button' : undefined}
            accessibilityLabel={`${item.title}, ${item.quantity} unidade(s)`}
            style={styles.item}
          >
            <View style={styles.thumbWrap}>
              <ProductImage uri={item.imageUrl} title={item.title} size={72} bg={light ? colors.muted : '#F3F3F3'} desaturated={light} />
              <View style={[styles.qty, light && styles.qtyLight]}>
                <Text variant="captionStrong" style={{ color: light ? colors.textSecondary : '#FFFFFF' }}>
                  {item.quantity}
                </Text>
              </View>
              {interactive && onEditItem ? (
                <View style={styles.pencil}>
                  <Ionicons name="pencil" size={11} color={colors.brandDark} />
                </View>
              ) : null}
            </View>
            <Text variant="smallStrong" tone={textTone} numberOfLines={1} center style={styles.itemTitle}>
              {item.title}
            </Text>
            {item.subtitle ? (
              <Text variant="caption" tone={mutedTone} numberOfLines={1} center>
                {item.subtitle}
              </Text>
            ) : null}
          </Pressable>
        ))}
        {interactive && onAddItems ? (
          <Pressable onPress={onAddItems} accessibilityRole="button" accessibilityLabel="Adicionar itens à caixa" style={({ pressed }) => [styles.addBlock, pressed && styles.pressed]}>
            <Ionicons name="add" size={18} color="#FFFFFF" />
            <Text variant="bodyStrong" tone="onDark" style={styles.addText}>
              Adicionar{'\n'}itens à caixa
            </Text>
          </Pressable>
        ) : null}
      </View>

      {gifts.length > 0 ? (
        <View style={styles.gifts}>
          <Pressable onPress={() => setGiftsOpen((v) => !v)} accessibilityRole="button" accessibilityState={{ expanded: giftsOpen }} style={styles.giftsHeader}>
            <Text variant="smallStrong" tone={textTone}>
              Seus brindes da próxima caixa
            </Text>
            <Ionicons name={giftsOpen ? 'chevron-up' : 'chevron-down'} size={18} color={light ? colors.textMuted : '#FFFFFF'} />
          </Pressable>
          {giftsOpen ? (
            <View style={styles.giftRow}>
              {gifts.map((g) => (
                <ProductImage key={g.id} uri={g.imageUrl} title={g.title} size={56} bg={light ? colors.muted : '#F3F3F3'} desaturated={light} />
              ))}
            </View>
          ) : null}
        </View>
      ) : null}

      {onEdit ? (
        <View style={styles.editWrap}>
          <Button title="Editar caixa" variant={light ? 'primary' : 'gold'} size="sm" full={false} onPress={onEdit} disabled={!canEdit || pendingPayment} style={styles.editBtn} />
        </View>
      ) : null}

      {editUntilLabel ? (
        <View style={styles.footer}>
          <Ionicons name="information-circle-outline" size={14} color={light ? colors.textMuted : colors.textOnDarkMuted} />
          <Text variant="caption" tone={mutedTone}>
            Você pode alterar sua caixa{' '}
            <Text variant="captionStrong" tone={textTone}>
              até {editUntilLabel}
            </Text>
            .
          </Text>
        </View>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  card: { borderRadius: radius.md, padding: space(4), gap: space(3) },
  cardDark: { backgroundColor: colors.brandDark },
  cardLight: { backgroundColor: colors.subtle },
  top: { flexDirection: 'row', alignItems: 'flex-start', gap: space(4), flexWrap: 'wrap' },
  topCol: { gap: 2 },
  grid: { flexDirection: 'row', flexWrap: 'wrap', gap: space(2) },
  item: { width: 76, alignItems: 'center', gap: 2 },
  thumbWrap: { position: 'relative', marginBottom: space(1) },
  qty: { position: 'absolute', top: -6, left: -6, width: 20, height: 20, borderRadius: 10, backgroundColor: '#1A1A1A', alignItems: 'center', justifyContent: 'center', borderWidth: 1.5, borderColor: colors.brandDark },
  qtyLight: { backgroundColor: colors.borderStrong, borderColor: colors.subtle },
  pencil: { position: 'absolute', top: -6, right: -6, width: 20, height: 20, borderRadius: 10, backgroundColor: colors.gold, alignItems: 'center', justifyContent: 'center' },
  itemTitle: { maxWidth: 76 },
  addBlock: {
    flex: 1,
    minWidth: 120,
    minHeight: 72,
    flexDirection: 'row',
    alignItems: 'center',
    gap: space(1.5),
    paddingHorizontal: space(3),
    borderRadius: radius.sm,
    borderWidth: 1,
    borderStyle: 'dashed',
    borderColor: colors.goldGradientEnd,
    backgroundColor: colors.brandDark2,
  },
  addText: { lineHeight: 17 },
  pressed: { opacity: 0.8 },
  gifts: { gap: space(2) },
  giftsHeader: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  giftRow: { flexDirection: 'row', gap: space(2), flexWrap: 'wrap' },
  editWrap: { alignItems: 'center' },
  editBtn: { minWidth: 140 },
  footer: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: space(1) },
});
