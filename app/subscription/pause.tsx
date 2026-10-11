import { useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { useRouter } from 'expo-router';
import { errorMessage } from '@/api/client';
import { useDashboard, usePauseReasons, usePauseSubscription } from '@/api/hooks';
import { Button, Card, EmptyState, Screen, Section, SkeletonCard, Text, toast } from '@/components';
import { ReasonPicker } from '@/features/subscription/ReasonPicker';
import { formatDate } from '@/lib/format';
import { capabilityReasonLabel } from '@/lib/labels';
import { colors, radius, space } from '@/theme';

export default function PauseScreen() {
  const router = useRouter();
  const { data: dashboard } = useDashboard();
  const reasons = usePauseReasons();
  const pause = usePauseSubscription();
  const [cycles, setCycles] = useState(1);
  const [reason, setReason] = useState<string | null>(null);
  const [answer, setAnswer] = useState<string | null>(null);

  const cap = dashboard?.capabilities.canPause;
  const maxCycles = Math.max(1, Math.min(2, cap?.maxCycles ?? 2));
  const selected = reasons.data?.find((r) => r.code === reason);

  if (cap && !cap.allowed) {
    return (
      <Screen>
        <EmptyState icon="⏸️" title="Pausa indisponível" description={capabilityReasonLabel(cap.reason, cap.until)} actionLabel="Voltar" onAction={() => router.back()} />
      </Screen>
    );
  }

  function submit() {
    if (!reason || !selected) {
      toast.error('Escolha um motivo.');
      return;
    }
    pause.mutate(
      {
        cycles,
        reason,
        answers: selected.followUp && answer ? [{ question: selected.followUp.question, answer }] : undefined,
      },
      {
        onSuccess: (sub) => {
          toast.success(sub.pause ? `Assinatura pausada. Retoma em ${formatDate(sub.pause.resumeAt)}.` : 'Assinatura pausada.');
          router.replace('/(tabs)');
        },
        onError: (e) => toast.error(errorMessage(e, 'Não foi possível pausar.')),
      },
    );
  }

  return (
    <Screen
      title="Pausar assinatura"
      subtitle="Suas cobranças e entregas ficam suspensas pelos ciclos escolhidos. Você pode retomar quando quiser."
      footer={<Button title={`Pausar por ${cycles} ciclo${cycles > 1 ? 's' : ''}`} onPress={submit} loading={pause.isPending} disabled={!reason} />}
    >
      {cap ? (
        <Card tone="elevated">
          <Text variant="small" tone="muted">
            Você tem {cap.creditsLeft ?? 0} crédito{(cap.creditsLeft ?? 0) === 1 ? '' : 's'} de pausa neste plano. Cada pausa usa 1 crédito, independentemente da duração.
          </Text>
        </Card>
      ) : null}

      <Section title="Duração">
        <View style={styles.options}>
          {Array.from({ length: maxCycles }, (_, i) => i + 1).map((n) => {
            const active = n === cycles;
            return (
              <Pressable key={n} onPress={() => setCycles(n)} accessibilityRole="radio" accessibilityState={{ selected: active }} style={[styles.option, active && styles.optionOn]}>
                <Text variant="title" tone={active ? 'accent' : 'default'}>
                  {n}
                </Text>
                <Text variant="caption" tone="muted">
                  {n === 1 ? 'ciclo' : 'ciclos'}
                </Text>
              </Pressable>
            );
          })}
        </View>
      </Section>

      <Section title="Motivo">
        {reasons.isLoading ? (
          <SkeletonCard lines={4} />
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

const styles = StyleSheet.create({
  options: { flexDirection: 'row', gap: space(3) },
  option: { flex: 1, alignItems: 'center', padding: space(4), borderRadius: radius.lg, borderWidth: 1, borderColor: colors.border, backgroundColor: colors.surface },
  optionOn: { borderColor: colors.accent, backgroundColor: colors.accentSoft },
});
