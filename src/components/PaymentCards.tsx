import { StyleSheet, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Image } from 'expo-image';
import { colors, radius, shadows, space } from '@/theme';
import { Button } from './Button';
import { RadioRow } from './RadioRow';
import { Text } from './Text';

// ---------- PixPaymentCard ----------

interface PixPaymentCardProps {
  qrCodeImageUrl?: string;
  qrCodeText: string;
  dueLabel: string;
  onCopy: () => void;
  /** Rodapé opcional (contador de expiração / "Já paguei"). */
  footer?: React.ReactNode;
  expired?: boolean;
  onRegenerate?: () => void;
  regenerating?: boolean;
}

/** "Pagamento único por PIX": QR grande, "Você deve pagar até …", copia-e-cola, "Copiar link". */
export function PixPaymentCard({ qrCodeImageUrl, qrCodeText, dueLabel, onCopy, footer, expired, onRegenerate, regenerating }: PixPaymentCardProps) {
  return (
    <View style={[styles.card, shadows.card]}>
      <Text variant="bodyStrong">Pagamento único por PIX</Text>
      <Text variant="body" tone="secondary">
        Para realizar o pagamento escaneie o QR Code ou copie e cole o código Pix no seu aplicativo de pagamento.
      </Text>
      <View style={styles.qrWrap}>
        {qrCodeImageUrl && !expired ? (
          <Image source={{ uri: qrCodeImageUrl }} style={styles.qr} contentFit="contain" accessibilityLabel="QR Code PIX" />
        ) : (
          <View style={[styles.qr, styles.qrPlaceholder]}>
            <Ionicons name="qr-code-outline" size={64} color={colors.textMuted} />
          </View>
        )}
      </View>
      <Text variant="body" center>
        Você deve pagar{' '}
        <Text variant="bodyStrong">até {dueLabel}</Text>
      </Text>
      {expired && onRegenerate ? (
        <Button title="Gerar novo PIX" variant="secondary" onPress={onRegenerate} loading={regenerating} />
      ) : (
        <>
          <View style={styles.codeBox}>
            <Text variant="mono" tone="secondary" numberOfLines={4} selectable>
              {qrCodeText}
            </Text>
          </View>
          <Button title="Copiar link" onPress={onCopy} full={false} style={styles.copyBtn} icon={<Ionicons name="copy-outline" size={16} color={colors.text} />} />
        </>
      )}
      {footer}
    </View>
  );
}

// ---------- PaymentFailedCard ----------

export type PaymentOption = 'card' | 'pix' | 'new-card';

interface PaymentFailedCardProps {
  title?: string;
  card?: { brand: string; lastFour: string; label?: string } | null;
  options: { key: PaymentOption; label: string; hint: string; enabled: boolean }[];
  value: PaymentOption;
  onChange: (v: PaymentOption) => void;
  primaryLabel?: string;
  onPrimary: () => void;
  primaryLoading?: boolean;
  onSupport?: () => void;
}

/** "Não foi possível processar seu pagamento": cartão com bandeira, opções em rádio, botões. */
export function PaymentFailedCard({ title = 'Não foi possível processar seu pagamento', card, options, value, onChange, primaryLabel = 'Regularizar assinatura', onPrimary, primaryLoading, onSupport }: PaymentFailedCardProps) {
  return (
    <View style={[styles.card, shadows.card]}>
      <Text variant="bodyStrong" tone="danger">
        {title}
      </Text>
      {card ? (
        <View style={styles.cardBox}>
          <View style={styles.brandDot}>
            <Ionicons name="card" size={16} color={colors.warning} />
          </View>
          <View style={styles.cardText}>
            <Text variant="body">
              {card.brand} • {card.label ?? 'Crédito'}
            </Text>
            <Text variant="body" tone="secondary">
              •••• {card.lastFour}
            </Text>
          </View>
          <Ionicons name="close-circle-outline" size={20} color={colors.danger} />
        </View>
      ) : null}
      <Text variant="body" tone="secondary">
        Regularize seu <Text variant="bodyStrong">pagamento</Text> escolhendo uma das opções abaixo:
      </Text>
      <View>
        {options.map((o) => (
          <RadioRow key={o.key} label={o.label} hint={o.hint} selected={value === o.key} onPress={() => onChange(o.key)} disabled={!o.enabled} />
        ))}
      </View>
      <Button title={primaryLabel} onPress={onPrimary} loading={primaryLoading} />
      {onSupport ? <Button title="Fale conosco" variant="secondary" onPress={onSupport} icon={<Ionicons name="headset-outline" size={16} color={colors.text} />} /> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  card: { backgroundColor: colors.surface, borderRadius: radius.md, padding: space(4), gap: space(3), marginBottom: space(3) },
  qrWrap: { alignItems: 'center' },
  qr: { width: 180, height: 180 },
  qrPlaceholder: { alignItems: 'center', justifyContent: 'center', backgroundColor: colors.subtle, borderRadius: radius.sm },
  codeBox: { backgroundColor: colors.subtle, borderRadius: radius.sm, padding: space(3) },
  copyBtn: { alignSelf: 'center', minWidth: 160 },
  cardBox: { flexDirection: 'row', alignItems: 'center', gap: space(3), padding: space(3), borderRadius: radius.sm, borderWidth: 1, borderColor: colors.borderStrong, backgroundColor: colors.subtle },
  brandDot: { width: 28, alignItems: 'center' },
  cardText: { flex: 1, gap: 2 },
});
