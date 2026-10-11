import type { ReactNode } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, shadows, space } from '@/theme';
import { Button } from './Button';
import { ProductImage } from './ProductImage';
import { Sheet } from './Sheet';
import { Text } from './Text';

interface BoxItemRowProps {
  title: string;
  spec?: string;
  flavor?: string;
  imageUrl?: string;
  /** Handle do produto/sabor (fallback para imagem local). */
  handle?: string;
  recurrenceLabel?: string;
  priceLabel?: string;
  fullPriceLabel?: string;
  /** Controle à direita (Stepper). */
  control?: ReactNode;
  onEdit?: () => void;
  editLabel?: string;
  disabled?: boolean;
  /** Conteúdo expandido (ex.: "Trocar recorrência" / "Remover item"). */
  expanded?: ReactNode;
}

/** Item da caixa (edição): thumb, nome bold, "250g - 25 Doses", "⟳ Recorrência de 60 dias", botão "Editar". */
export function BoxItemRow({ title, spec, flavor, imageUrl, handle, recurrenceLabel, priceLabel, fullPriceLabel, control, onEdit, editLabel = 'Editar', disabled, expanded }: BoxItemRowProps) {
  return (
    <View style={[styles.card, shadows.card]}>
      <View style={styles.row}>
        <ProductImage uri={imageUrl} handle={handle} title={title} size={56} bg={colors.subtle} />
        <View style={styles.text}>
          <Text variant="bodyStrong" numberOfLines={2}>
            {title}
          </Text>
          {flavor ? (
            <Text variant="small" tone="secondary" numberOfLines={1}>
              {flavor}
            </Text>
          ) : null}
          {spec ? (
            <Text variant="small" tone="secondary" numberOfLines={1}>
              {spec}
            </Text>
          ) : null}
          {recurrenceLabel ? (
            <View style={styles.recurrence}>
              <Ionicons name="sync-outline" size={12} color={colors.textSecondary} />
              <Text variant="caption" tone="secondary" numberOfLines={1}>
                {recurrenceLabel}
              </Text>
            </View>
          ) : null}
          {priceLabel ? (
            <View style={styles.price}>
              <Text variant="smallStrong">{priceLabel}</Text>
              {fullPriceLabel ? (
                <Text variant="caption" tone="dim" style={styles.strike}>
                  {fullPriceLabel}
                </Text>
              ) : null}
            </View>
          ) : null}
        </View>
        <View style={styles.right}>
          {onEdit ? <Button title={editLabel} size="xs" full={false} onPress={onEdit} disabled={disabled} /> : null}
          {control}
        </View>
      </View>
      {expanded ? <View style={styles.expanded}>{expanded}</View> : null}
    </View>
  );
}

export interface ItemAction {
  key: string;
  label: string;
  onPress: () => void;
  danger?: boolean;
  disabled?: boolean;
}

interface ItemActionSheetProps {
  visible: boolean;
  onClose: () => void;
  title?: string;
  actions: ItemAction[];
}

/** Menu de ação do item: Trocar sabor / Trocar tamanho / Trocar recorrência / Remover item (vermelho) + Cancelar. */
export function ItemActionSheet({ visible, onClose, title, actions }: ItemActionSheetProps) {
  return (
    <Sheet visible={visible} onClose={onClose} title={title} plain>
      <View style={styles.sheetGroup}>
        {actions.map((a, idx) => (
          <Pressable
            key={a.key}
            onPress={() => {
              onClose();
              a.onPress();
            }}
            disabled={a.disabled}
            accessibilityRole="button"
            style={({ pressed }) => [styles.sheetRow, idx < actions.length - 1 && styles.sheetBorder, pressed && styles.pressed, a.disabled && styles.disabled]}
          >
            <Text variant="body" tone={a.danger ? 'danger' : 'default'} center>
              {a.label}
            </Text>
          </Pressable>
        ))}
      </View>
      <Pressable onPress={onClose} accessibilityRole="button" style={({ pressed }) => [styles.sheetGroup, styles.sheetRow, styles.cancel, pressed && styles.pressed]}>
        <Text variant="bodyMedium" center>
          Cancelar
        </Text>
      </Pressable>
    </Sheet>
  );
}

const styles = StyleSheet.create({
  card: { backgroundColor: colors.surface, borderRadius: radius.md, padding: space(3), marginBottom: space(2) },
  row: { flexDirection: 'row', alignItems: 'flex-start', gap: space(3) },
  text: { flex: 1, gap: 2 },
  recurrence: { flexDirection: 'row', alignItems: 'center', gap: 4, marginTop: 2 },
  price: { flexDirection: 'row', alignItems: 'center', gap: space(1.5), marginTop: 2 },
  strike: { textDecorationLine: 'line-through' },
  right: { alignItems: 'flex-end', gap: space(2) },
  expanded: { marginTop: space(3), borderTopWidth: 1, borderTopColor: colors.border, paddingTop: space(2) },
  sheetGroup: { backgroundColor: colors.surface, borderRadius: radius.sm, overflow: 'hidden', marginBottom: space(2), ...shadows.card },
  sheetRow: { paddingVertical: space(3.5), paddingHorizontal: space(4) },
  sheetBorder: { borderBottomWidth: 1, borderBottomColor: colors.border },
  cancel: { marginBottom: 0 },
  pressed: { backgroundColor: colors.subtle },
  disabled: { opacity: 0.4 },
});
