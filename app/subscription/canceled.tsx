import { useRouter } from 'expo-router';
import { errorMessage } from '@/api/client';
import { useDashboard, useReactivateSubscription } from '@/api/hooks';
import { AlertCard, Card, EmptyState, Money, Row, Screen, SkeletonCard, Text, toast } from '@/components';
import { Ionicons } from '@expo/vector-icons';
import { View } from 'react-native';
import { colors } from '@/theme';
import { formatDate } from '@/lib/format';
import { capabilityReasonLabel, frequencyLabel } from '@/lib/labels';

export default function CanceledScreen() {
  const router = useRouter();
  const { data, isLoading } = useDashboard();
  const reactivate = useReactivateSubscription();
  const sub = data?.subscription;
  const cap = data?.capabilities.canReactivate;

  if (isLoading || !data) {
    return (
      <Screen>
        <SkeletonCard lines={3} />
      </Screen>
    );
  }
  if (!sub || sub.status !== 'canceled') {
    return (
      <Screen>
        <EmptyState icon="✅" title="Sua assinatura está ativa" actionLabel="Ir para o início" onAction={() => router.replace('/(tabs)')} />
      </Screen>
    );
  }

  function onReactivate() {
    reactivate.mutate(undefined, {
      onSuccess: () => {
        toast.success('Assinatura reativada. Que bom ter você de volta!');
        router.replace('/(tabs)');
      },
      onError: (e) => toast.error(errorMessage(e, 'Não foi possível reativar.')),
    });
  }

  return (
    <Screen>
      <AlertCard variant="canceled" title="Sentimos sua falta!" primaryLabel={cap?.allowed ? 'Retomar assinatura' : undefined} onPrimary={cap?.allowed ? onReactivate : undefined} primaryLoading={reactivate.isPending}>
        <Text variant="body" tone="secondary">
          {data.user.firstName}, assine novamente o Caffeine Army Prime e garanta seus benefícios novamente:
        </Text>
        {[
          ['Desconto', ' nos produtos Caffeine Army'],
          ['Praticidade', ' em receber seu SuperCoffee em casa'],
          ['Flexibilidade', ' para personalizar sabor, quantidade e tamanho das suas latas'],
          ['Frete grátis', ' em compras avulsas no site'],
        ].map(([b, rest]) => (
          <View key={b} style={{ flexDirection: 'row', alignItems: 'flex-start', gap: 8 }}>
            <Ionicons name="checkmark-circle-outline" size={16} color={colors.gold} style={{ marginTop: 1 }} />
            <Text variant="body" tone="secondary" style={{ flex: 1 }}>
              <Text variant="bodyStrong">{b}</Text>
              {rest}
            </Text>
          </View>
        ))}
        {data.lastCanceled ? (
          <Text variant="caption" tone="dim">
            Cancelada em {formatDate(data.lastCanceled.canceledAt)}.
          </Text>
        ) : null}
      </AlertCard>
      <Card title={sub.planName} subtitle={frequencyLabel[sub.frequency]}>
        {sub.items.map((i) => (
          <Row key={i.id}>
            <Text variant="small" tone="muted">
              {i.quantity}× {i.title}
              {i.flavor ? ` · ${i.flavor}` : ''}
            </Text>
          </Row>
        ))}
        <Row style={{ marginTop: 8 }}>
          <Text variant="small" tone="muted">
            Valor por ciclo
          </Text>
          <Money value={sub.total} variant="bodyStrong" />
        </Row>
      </Card>
      {cap?.allowed ? (
        <Text variant="caption" tone="dim" center style={{ marginTop: 4 }}>
          Sua caixa volta com os mesmos itens, plano e desconto. A primeira cobrança acontece na reativação.
        </Text>
      ) : (
        <Card>
          <Text variant="small" tone="muted">
            {capabilityReasonLabel(cap?.reason, cap?.until)}
          </Text>
        </Card>
      )}
    </Screen>
  );
}
