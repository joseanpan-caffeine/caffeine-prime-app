import { useRouter } from 'expo-router';
import { errorMessage } from '@/api/client';
import { useDashboard, useReactivateSubscription } from '@/api/hooks';
import { Button, Card, EmptyState, Money, Row, Screen, SkeletonCard, Text, toast } from '@/components';
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
    <Screen title="Assinatura cancelada" subtitle={data.lastCanceled ? `Cancelada em ${formatDate(data.lastCanceled.canceledAt)}.` : undefined}>
      <Card tone="elevated" title={sub.planName} subtitle={frequencyLabel[sub.frequency]}>
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
        <>
          <Button title="Reativar assinatura" onPress={onReactivate} loading={reactivate.isPending} />
          <Text variant="caption" tone="dim" center style={{ marginTop: 12 }}>
            Sua caixa volta com os mesmos itens, plano e desconto. A primeira cobrança acontece na reativação.
          </Text>
        </>
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
