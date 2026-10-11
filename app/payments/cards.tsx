import { useState } from 'react';
import { Alert, StyleSheet, Switch, View } from 'react-native';
import { errorMessage } from '@/api/client';
import { useAddCard, useDashboard, usePaymentProfiles, useRemoveCard } from '@/api/hooks';
import { Badge, Button, Card, EmptyState, ListItem, Row, Screen, Sheet, SkeletonCard, Text, toast } from '@/components';
import { CardForm } from '@/features/payments/CardForm';
import { capabilityReasonLabel } from '@/lib/labels';
import type { TokenizedCard } from '@/lib/vindi';
import { colors, space } from '@/theme';

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
        <Card tone="accent">
          <Text variant="small" tone="muted">
            {capabilityReasonLabel(canChange.reason, canChange.until)}
          </Text>
        </Card>
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
        <Card padded={false} style={styles.list}>
          {cards.map((c, idx) => (
            <ListItem
              key={c.id}
              title={`${c.brand} •••• ${c.lastFour}`}
              subtitle={`${c.holderName} · válido até ${c.expiration}`}
              last={idx === cards.length - 1}
              left={<Text variant="heading">💳</Text>}
              right={
                <View style={styles.right}>
                  {c.isDefault ? <Badge label="Padrão" tone="accent" /> : null}
                  {!c.isDefault ? (
                    <Button title="Remover" variant="ghost" size="sm" full={false} onPress={() => confirmRemove(c.id, `${c.brand} final ${c.lastFour}`)} loading={removeCard.isPending && removeCard.variables === c.id} />
                  ) : null}
                </View>
              }
            />
          ))}
        </Card>
      )}

      <Sheet visible={adding} onClose={() => setAdding(false)} title="Novo cartão">
        <Row style={styles.switchRow}>
          <Text variant="small">Usar como cartão padrão</Text>
          <Switch value={setDefault} onValueChange={setSetDefault} trackColor={{ true: colors.accentDark, false: colors.borderStrong }} thumbColor={setDefault ? colors.accent : colors.textMuted} />
        </Row>
        <CardForm submitLabel="Salvar cartão" onTokenized={onTokenized} busy={addCard.isPending} />
      </Sheet>
    </Screen>
  );
}

const styles = StyleSheet.create({
  list: { paddingHorizontal: space(4) },
  right: { alignItems: 'flex-end', gap: space(1) },
  switchRow: { marginBottom: space(3) },
});
