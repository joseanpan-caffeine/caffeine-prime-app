import { useRouter } from 'expo-router';
import { errorMessage } from '@/api/client';
import { useDashboard, useResumeSubscription } from '@/api/hooks';
import { AlertCard, Card, EmptyState, Money, Row, Screen, SkeletonCard, Text, toast } from '@/components';
import { describeDaysUntil, formatDate } from '@/lib/format';
import { formatShortDate } from '@/lib/prime';
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
    <Screen>
      <AlertCard
        variant="paused"
        title="Assinatura pausada"
        primaryLabel={cap?.allowed ? 'Retomar assinatura' : undefined}
        onPrimary={cap?.allowed ? onResume : undefined}
        primaryLoading={resume.isPending}
      >
        <Text variant="body" tone="secondary">
          {sub.pause ? `Sua assinatura está pausada por ${sub.pause.cycles} ${sub.pause.cycles === 1 ? 'ciclo' : 'ciclos'}.` : 'Sua assinatura está pausada.'}
        </Text>
        {sub.pause ? (
          <Text variant="body" tone="secondary">
            O próximo pagamento será efetivado automaticamente em <Text variant="bodyStrong">{formatShortDate(sub.pause.resumeAt, true)}</Text> ({describeDaysUntil(sub.pause.resumeAt)}).
          </Text>
        ) : null}
        {cap?.allowed && cap.closesAt ? (
          <Text variant="small" tone="secondary">
            Você pode desfazer a pausa até <Text variant="smallStrong">{formatShortDate(cap.closesAt, true)}</Text> (5 dias antes da cobrança).
          </Text>
        ) : null}
      </AlertCard>
      <Card>
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
      {!cap?.allowed ? (
        <Card>
          <Text variant="small" tone="muted">
            {capabilityReasonLabel(cap?.reason, cap?.until)}
          </Text>
        </Card>
      ) : null}
      <Text variant="caption" tone="dim" center>
        Durante a pausa, cada ciclo gera uma fatura de R$ 0,00 sem envio — é o esperado. Ao retomar, a próxima cobrança acontece no ciclo seguinte com a sua caixa atual.
      </Text>
    </Screen>
  );
}
