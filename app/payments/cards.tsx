import { useState } from 'react';
import { Alert, Pressable, StyleSheet, Switch, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { errorMessage } from '@/api/client';
import { useAddCard, useDashboard, usePaymentProfiles, useRemoveCard } from '@/api/hooks';
import { AlertCard, Badge, Button, CardBrandLogo, EmptyState, Radio, Row, Screen, Sheet, SkeletonCard, Text, toast } from '@/components';
import { CardForm } from '@/features/payments/CardForm';
import { capabilityReasonLabel } from '@/lib/labels';
import type { TokenizedCard } from '@/lib/vindi';
import { colors, radius, space } from '@/theme';

export default function CardsScreen() {
  const { data: cards, isLoading, isError, error, refetch, isRefetching } = usePaymentProfiles();
  const { data: dashboard } = useDashboard();
  const addCard = useAddCard();
  const removeCard = useRemoveCard();
  const [adding, setAdding] = useState(false);
  const [setDefault, setSetDefault] = useState(true);

  const canChange = dashboard?.capabilities.canChangeCard;

  async function onTokenized(card: TokenizedCard) {
    await addCard.mutateAsync(
      { gatewayToken: card.gatewayToken, paymentCompanyCode: card.paymentCompanyCode, setAsDefault: setDefault },
      {
        onSuccess: () => {
          toast.success(`Cartão final ${card.lastFour} adicionado.`);
          setAdding(false);
        },
        onError: (e) => toast.error(errorMessage(e, 'Não foi possível salvar o cartão.')),
      },
    ).catch(() => undefined);
  }

  function confirmRemove(id: string, label: string) {
    Alert.alert('Remover cartão', `Remover ${label}?`, [
      { text: 'Cancelar', style: 'cancel' },
      {
        text: 'Remover',
        style: 'destructive',
        onPress: () => removeCard.mutate(id, { onSuccess: () => toast.success('Cartão removido.'), onError: (e) => toast.error(errorMessage(e)) }),
      },
    ]);
  }

  return (
    <Screen title="Cartões" subtitle="O cartão padrão é usado nas cobranças da assinatura." onRefresh={refetch} refreshing={isRefetching} footer={<Button title="Adicionar cartão" onPress={() => setAdding(true)} disabled={canChange ? !canChange.allowed : false} />}>
      {canChange && !canChange.allowed ? (
        <AlertCard variant="why_cant_edit" title="Troca de cartão indisponível">
          {capabilityReasonLabel(canChange.reason, canChange.until)}
        </AlertCard>
      ) : null}
      {isLoading ? (
        <>
          <SkeletonCard lines={1} />
          <SkeletonCard lines={1} />
        </>
      ) : isError ? (
        <EmptyState icon="⚠️" title="Não deu para carregar" description={errorMessage(error)} actionLabel="Tentar de novo" onAction={() => refetch()} />
      ) : !cards || cards.length === 0 ? (
        <EmptyState icon="💳" title="Nenhum cartão salvo" description="Adicione um cartão de crédito para as cobranças da assinatura." />
      ) : (
        <View>
          {cards.map((c) => {
            const expired = isExpired(c.expiration);
            return (
              <View key={c.id} style={[styles.cardRow, c.isDefault && styles.cardRowOn]}>
                <Radio selected={c.isDefault} />
                <CardBrandLogo brand={c.brand} />
                <View style={styles.flex1}>
                  <Text variant="body">
                    {c.brand} - final <Text variant="bodyStrong">{c.lastFour}</Text>
                  </Text>
                  <Text variant="caption" tone="dim">
                    {c.holderName} · válido até {c.expiration}
                  </Text>
                </View>
                {expired ? <Badge label="Cartão expirado" tone="pending" size="sm" /> : c.isDefault ? <Badge label="Padrão" tone="accent" size="sm" /> : null}
                {!c.isDefault ? (
                  <Pressable onPress={() => confirmRemove(c.id, `${c.brand} final ${c.lastFour}`)} hitSlop={8} accessibilityRole="button" accessibilityLabel="Remover cartão" disabled={removeCard.isPending}>
                    <Ionicons name="trash-outline" size={18} color={colors.danger} />
                  </Pressable>
                ) : null}
              </View>
            );
          })}
        </View>
      )}

      <Sheet visible={adding} onClose={() => setAdding(false)} title="Novo cartão">
        <Row style={styles.switchRow}>
          <Text variant="small">Usar como cartão padrão</Text>
          <Switch value={setDefault} onValueChange={setSetDefault} trackColor={{ true: colors.primaryStrong, false: colors.borderStrong }} thumbColor={setDefault ? colors.gold : colors.surface} />
        </Row>
        <CardForm submitLabel="Salvar cartão" onTokenized={onTokenized} busy={addCard.isPending} />
      </Sheet>
    </Screen>
  );
}

/** "MM/YYYY" já vencido? */
function isExpired(expiration: string): boolean {
  const m = /^(\d{2})\/(\d{4})$/.exec(expiration);
  if (!m) return false;
  const now = new Date();
  const year = Number(m[2]);
  const month = Number(m[1]);
  return year < now.getFullYear() || (year === now.getFullYear() && month < now.getMonth() + 1);
}

const styles = StyleSheet.create({
  flex1: { flex: 1 },
  cardRow: { flexDirection: 'row', alignItems: 'center', gap: space(3), backgroundColor: colors.surface, borderRadius: radius.sm, borderWidth: 1, borderColor: colors.borderStrong, padding: space(3), marginBottom: space(2) },
  cardRowOn: { borderColor: colors.primary, backgroundColor: '#FFFBEB' },
  switchRow: { marginBottom: space(3) },
});
