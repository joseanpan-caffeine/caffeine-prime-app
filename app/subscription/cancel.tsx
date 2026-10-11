import { useState } from 'react';
import { Alert } from 'react-native';
import { useRouter } from 'expo-router';
import { errorMessage } from '@/api/client';
import { useCancelReasons, useCancelSubscription, useDashboard } from '@/api/hooks';
import { AlertCard, Button, Card, EmptyState, Screen, Section, SkeletonCard, Text, toast } from '@/components';
import { ReasonPicker } from '@/features/subscription/ReasonPicker';
import { capabilityReasonLabel } from '@/lib/labels';

export default function CancelScreen() {
  const router = useRouter();
  const { data: dashboard } = useDashboard();
  const reasons = useCancelReasons();
  const cancel = useCancelSubscription();
  const [reason, setReason] = useState<string | null>(null);
  const [answer, setAnswer] = useState<string | null>(null);

  const cap = dashboard?.capabilities.canCancel;
  const sub = dashboard?.subscription;
  const remaining = cap?.remainingCommitmentMonths ?? sub?.remainingCommitmentMonths ?? 0;
  const selected = reasons.data?.find((r) => r.code === reason);

  if (cap && !cap.allowed) {
    return (
      <Screen>
        <EmptyState icon="🔒" title="Cancelamento indisponível" description={capabilityReasonLabel(cap.reason, cap.until)} actionLabel="Voltar" onAction={() => router.back()} />
      </Screen>
    );
  }

  function submit() {
    if (!reason || !selected) {
      toast.error('Escolha um motivo.');
      return;
    }
    Alert.alert('Cancelar assinatura', 'Tem certeza? Você perde os descontos do plano e os brindes acumulados.', [
      { text: 'Manter assinatura', style: 'cancel' },
      {
        text: 'Cancelar mesmo assim',
        style: 'destructive',
        onPress: () =>
          cancel.mutate(
            { reason, answers: selected.followUp && answer ? [{ question: selected.followUp.question, answer }] : undefined },
            {
              onSuccess: () => {
                toast.info('Assinatura cancelada. Você pode reativar quando quiser.');
                router.replace('/subscription/canceled');
              },
              onError: (e) => toast.error(errorMessage(e, 'Não foi possível cancelar.')),
            },
          ),
      },
    ]);
  }

  return (
    <Screen
      title="Cancelar assinatura"
      subtitle="Antes de ir, conta pra gente o motivo. Isso ajuda a melhorar o Prime."
      footer={<Button title="Cancelar e perder benefícios" variant="danger" onPress={submit} loading={cancel.isPending} disabled={!reason} />}
    >
      {remaining > 0 ? (
        <AlertCard
          variant="paused"
          title="Que tal pausar em vez de cancelar?"
          primaryLabel={dashboard?.capabilities.canPause.allowed ? 'Prefiro pausar' : undefined}
          onPrimary={dashboard?.capabilities.canPause.allowed ? () => router.replace('/subscription/pause') : undefined}
        >
          <Text variant="body" tone="secondary">
            Faltam <Text variant="bodyStrong">{remaining} {remaining === 1 ? 'mês' : 'meses'}</Text> para concluir a fidelidade do seu plano
            {cap?.earlyWindow ? ' e você está na janela de cancelamento antecipado' : ''}. Ao cancelar agora você perde o desconto do plano.
            {dashboard?.capabilities.canPause.allowed ? ' Pausar mantém seus benefícios e não cobra nada enquanto durar.' : ''}
          </Text>
        </AlertCard>
      ) : null}

      <Section title="Motivo">
        {reasons.isLoading ? (
          <SkeletonCard lines={5} />
        ) : reasons.data ? (
          <ReasonPicker reasons={reasons.data} value={reason} onChange={(c) => { setReason(c); setAnswer(null); }} followUpAnswer={answer} onFollowUp={setAnswer} />
        ) : (
          <Card>
            <Text variant="small" tone="danger">
              {errorMessage(reasons.error, 'Não foi possível carregar os motivos.')}
            </Text>
            <Button title="Tentar de novo" variant="ghost" size="sm" onPress={() => reasons.refetch()} />
          </Card>
        )}
      </Section>
    </Screen>
  );
}
