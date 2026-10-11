import { useRouter } from 'expo-router';
import { errorMessage } from '@/api/client';
import { useDashboard, useResumeSubscription } from '@/api/hooks';
import { Button, Card, EmptyState, Money, Row, Screen, SkeletonCard, Text, toast } from '@/components';
import { describeDaysUntil, formatDate } from '@/lib/format';
import { capabilityReasonLabel } from '@/lib/labels';

export default function PausedScreen() {
  const router = useRouter();
  const { data, isLoading } = useDashboard();
  const resume = useResumeSubscription();
  const sub = data?.subscription;
  const cap = data?.capabilities.canResume;

  if (isLoading || !data) {
    return (
      <Screen>
        <SkeletonCard lines={3} />
      </Screen>
    );
  }
  if (!sub || sub.status !== 'paused') {
    return (
      <Screen>
        <EmptyState icon="▶️" title="Sua assinatura não está pausada" actionLabel="Voltar" onAction={() => router.back()} />
      </Screen>
    );
  }

  function onResume() {
    resume.mutate(undefined, {
      onSuccess: () => {
        toast.success('Assinatura retomada. Bem-vindo de volta!');
        router.replace('/(tabs)');
      },
      onError: (e) => toast.error(errorMessage(e, 'Não foi possível retomar.')),
    });
  }

  return (
    <Screen title="Assinatura pausada" subtitle={sub.pause ? `Retoma automaticamente ${describeDaysUntil(sub.pause.resumeAt)}, em ${formatDate(sub.pause.resumeAt)}.` : undefined}>
      <Card tone="elevated">
        {sub.pause ? (
          <>
            <Row>
              <Text variant="small" tone="muted">
                Pausada em
              </Text>
              <Text variant="small">{formatDate(sub.pause.pausedAt)}</Text>
            </Row>
            <Row>
              <Text variant="small" tone="muted">
                Ciclos restantes
              </Text>
              <Text variant="small">
                {sub.pause.remainingCycles} de {sub.pause.cycles}
              </Text>
            </Row>
          </>
        ) : null}
        <Row>
          <Text variant="small" tone="muted">
            Valor da caixa
          </Text>
          <Money value={sub.total} variant="small" />
        </Row>
      </Card>
      {cap?.allowed ? (
        <Button title="Retomar agora" onPress={onResume} loading={resume.isPending} />
      ) : (
        <Card>
          <Text variant="small" tone="muted">
            {capabilityReasonLabel(cap?.reason, cap?.until)}
          </Text>
        </Card>
      )}
      <Text variant="caption" tone="dim" center>
        Ao retomar, a próxima cobrança acontece no ciclo seguinte com a sua caixa atual.
      </Text>
    </Screen>
  );
}
