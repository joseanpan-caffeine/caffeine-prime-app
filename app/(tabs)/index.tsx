import { Alert, Linking, Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { useRouter } from 'expo-router';
import { Image } from 'expo-image';
import type { Banner, Dashboard, Subscription, SubscriptionStatus } from '@/api/contracts';
import { errorMessage } from '@/api/client';
import { useDashboard, useUndoSchedule } from '@/api/hooks';
import { Badge, Button, Card, EmptyState, Money, Row, Screen, Section, SkeletonCard, Text, toast } from '@/components';
import type { BadgeTone } from '@/components/Badge';
import { describeDaysUntil, formatDate } from '@/lib/format';
import { frequencyLabel, fulfillmentLabel, subscriptionStatusLabel } from '@/lib/labels';
import { useAuthStore } from '@/store/auth';
import { colors, radius, space } from '@/theme';

const statusTone: Record<SubscriptionStatus, BadgeTone> = {
  active: 'success',
  future: 'info',
  paused: 'warning',
  canceled: 'danger',
  fraud_review: 'warning',
};

function greeting(): string {
  const h = new Date().getHours();
  if (h < 12) return 'Bom dia';
  if (h < 18) return 'Boa tarde';
  return 'Boa noite';
}

export default function Home() {
  const router = useRouter();
  const user = useAuthStore((s) => s.user);
  const { data, isLoading, isError, error, refetch, isRefetching } = useDashboard();
  const undo = useUndoSchedule();

  const firstName = data?.user.firstName || user?.firstName || '';

  const header = (
    <View style={styles.greeting}>
      <View style={styles.greetingText}>
        <Text variant="small" tone="muted">
          {greeting()},
        </Text>
        <Text variant="title">{firstName || 'assinante'}</Text>
      </View>
      {data?.subscription ? (
        <Badge label={subscriptionStatusLabel[data.subscription.status]} tone={statusTone[data.subscription.status]} />
      ) : null}
    </View>
  );

  if (isLoading) {
    return (
      <Screen safeTop>
        {header}
        <SkeletonCard lines={2} />
        <SkeletonCard lines={4} />
        <SkeletonCard lines={2} />
      </Screen>
    );
  }

  if (isError || !data) {
    return (
      <Screen safeTop onRefresh={refetch} refreshing={isRefetching}>
        {header}
        <EmptyState icon="⚠️" title="Não deu para carregar" description={errorMessage(error)} actionLabel="Tentar de novo" onAction={() => refetch()} />
      </Screen>
    );
  }

  const sub = data.subscription;
  const caps = data.capabilities;

  function onUndo() {
    Alert.alert('Desfazer mudança', 'A mudança agendada será descartada e sua caixa atual continua como está.', [
      { text: 'Manter', style: 'cancel' },
      {
        text: 'Desfazer',
        style: 'destructive',
        onPress: () =>
          undo.mutate(undefined, {
            onSuccess: () => toast.success('Mudança desfeita.'),
            onError: (e) => toast.error(errorMessage(e)),
          }),
      },
    ]);
  }

  return (
    <Screen safeTop onRefresh={refetch} refreshing={isRefetching}>
      {header}

      {caps.hasPendingBill && caps.pendingBill ? (
        <Card tone="accent" title="Fatura pendente" subtitle={`Vence ${describeDaysUntil(caps.pendingBill.dueAt)} · ${formatDate(caps.pendingBill.dueAt)}`}>
          <Money value={caps.pendingBill.amount} variant="display" />
          <Text variant="small" tone="muted" style={styles.mt2}>
            Pague para liberar a edição da caixa e garantir o envio.
          </Text>
          <View style={styles.ctaRow}>
            {caps.pendingBill.pixAvailable ? (
              <Button title="Pagar com PIX" onPress={() => router.push({ pathname: '/payments/pay/[billId]', params: { billId: caps.pendingBill!.id, method: 'pix' } })} style={styles.flex1} />
            ) : null}
            <Button
              title="Pagar com cartão"
              variant={caps.pendingBill.pixAvailable ? 'secondary' : 'primary'}
              onPress={() => router.push({ pathname: '/payments/pay/[billId]', params: { billId: caps.pendingBill!.id, method: 'card' } })}
              style={styles.flex1}
            />
          </View>
        </Card>
      ) : null}

      {sub ? <StatusCard sub={sub} data={data} /> : null}

      {sub?.scheduledChange ? (
        <Card title="Mudança agendada" subtitle={`Vale a partir de ${formatDate(sub.scheduledChange.appliesAt)}${sub.scheduledChange.nextCycleOnly ? ' · só no próximo ciclo' : ''}`}>
          <Text variant="small" tone="muted">
            {sub.scheduledChange.planName} · {frequencyLabel[sub.scheduledChange.frequency]} ·{' '}
            {sub.scheduledChange.items.reduce((n, i) => n + i.quantity, 0)} itens
          </Text>
          <Row style={styles.mt2}>
            <Money value={sub.scheduledChange.total} variant="heading" />
            <Button title="Desfazer" variant="ghost" size="sm" full={false} onPress={onUndo} loading={undo.isPending} />
          </Row>
        </Card>
      ) : null}

      {data.tracking ? (
        <Card
          title="Seu pedido"
          subtitle={data.tracking.carrier ? `${data.tracking.carrier}${data.tracking.trackingCode ? ` · ${data.tracking.trackingCode}` : ''}` : undefined}
          onPress={data.latestBill ? () => router.push({ pathname: '/orders/[billId]', params: { billId: data.latestBill!.id } }) : undefined}
          right={<Badge label={fulfillmentLabel[data.tracking.status]} tone={data.tracking.status === 'delivered' ? 'success' : data.tracking.status === 'failed' ? 'danger' : 'info'} />}
        >
          {data.tracking.estimatedDeliveryAt ? (
            <Text variant="small" tone="muted">
              Previsão de entrega: {formatDate(data.tracking.estimatedDeliveryAt)}
            </Text>
          ) : null}
          {data.tracking.events[0] ? (
            <Text variant="small" style={styles.mt1}>
              {data.tracking.events[0].description}
            </Text>
          ) : null}
        </Card>
      ) : null}

      {sub ? (
        <Card title="Sua caixa" subtitle={`${sub.planName} · ${frequencyLabel[sub.frequency]}`} right={<Money value={sub.total} variant="heading" />}>
          {sub.items.map((item) => (
            <Row key={item.id} style={styles.item}>
              <View style={styles.flex1}>
                <Text variant="bodyStrong" numberOfLines={1}>
                  {item.quantity}× {item.title}
                </Text>
                {item.flavor || item.recurrence || item.isGift ? (
                  <Text variant="caption" tone="muted">
                    {[item.flavor, item.recurrence ? 'a cada 60 dias' : null, item.isGift ? 'brinde' : null].filter(Boolean).join(' · ')}
                  </Text>
                ) : null}
              </View>
              <Money value={item.isGift ? 0 : item.finalPrice.amount * item.quantity} variant="small" tone="muted" />
            </Row>
          ))}
          <Button title="Editar caixa" variant="secondary" size="sm" onPress={() => router.push('/(tabs)/box')} style={styles.mt3} />
        </Card>
      ) : null}

      <View style={styles.statsRow}>
        <Card style={styles.stat} tone="elevated">
          <Text variant="caption" tone="muted">
            ECONOMIA 12 MESES
          </Text>
          <Money value={data.savings.last12Months} variant="heading" tone="success" />
          <Text variant="caption" tone="dim">
            desde o início: {data.savings.sinceStart.amount.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' })}
          </Text>
        </Card>
        <Card style={styles.stat} tone="elevated">
          <Text variant="caption" tone="muted">
            {data.wallet.label.toUpperCase()}
          </Text>
          <Text variant="heading" tone="accent">
            {data.wallet.points.toLocaleString('pt-BR')} pts
          </Text>
          <Text variant="caption" tone="dim">
            Caffeine X
          </Text>
        </Card>
      </View>

      {data.banners.length > 0 ? <Banners banners={data.banners} /> : null}
    </Screen>
  );
}

function StatusCard({ sub, data }: { sub: Subscription; data: Dashboard }) {
  const router = useRouter();
  const caps = data.capabilities;

  if (sub.status === 'paused' && sub.pause) {
    return (
      <Card tone="elevated" title="Assinatura pausada" subtitle={`Retoma ${describeDaysUntil(sub.pause.resumeAt)} · ${formatDate(sub.pause.resumeAt)}`}>
        <Text variant="small" tone="muted">
          {sub.pause.remainingCycles} de {sub.pause.cycles} ciclo(s) de pausa restante(s).
        </Text>
        {caps.canResume.allowed ? (
          <Button title="Retomar agora" size="sm" onPress={() => router.push('/subscription/paused')} style={styles.mt3} />
        ) : null}
      </Card>
    );
  }

  if (sub.status === 'canceled') {
    return (
      <Card tone="elevated" title="Assinatura cancelada" subtitle={data.lastCanceled ? `Cancelada em ${formatDate(data.lastCanceled.canceledAt)}` : undefined}>
        <Text variant="small" tone="muted">
          Sentimos sua falta. Reative e sua caixa volta com os mesmos benefícios.
        </Text>
        {caps.canReactivate.allowed ? (
          <Button title="Reativar assinatura" size="sm" onPress={() => router.push('/subscription/canceled')} style={styles.mt3} />
        ) : null}
      </Card>
    );
  }

  return (
    <Card tone="elevated">
      <Row>
        <View style={styles.flex1}>
          <Text variant="caption" tone="muted">
            PRÓXIMA COBRANÇA
          </Text>
          <Text variant="heading">{describeDaysUntil(sub.nextBillingAt)}</Text>
          <Text variant="small" tone="muted">
            {formatDate(sub.nextBillingAt)} · ciclo {sub.currentCycle}
          </Text>
        </View>
        <View style={styles.right}>
          <Text variant="caption" tone="muted">
            VALOR
          </Text>
          <Money value={sub.total} variant="heading" tone="accent" />
          {sub.paymentProfile ? (
            <Text variant="caption" tone="dim">
              {sub.paymentProfile.brand} •••• {sub.paymentProfile.lastFour}
            </Text>
          ) : null}
        </View>
      </Row>
      {!caps.canEdit.allowed && caps.canEdit.reason === 'EDIT_WINDOW_CLOSED' ? (
        <View style={styles.notice}>
          <Text variant="caption" tone="accent">
            Janela de edição fechada: sua caixa já está sendo preparada.
          </Text>
        </View>
      ) : null}
      <View style={styles.quick}>
        {caps.canPause.allowed ? (
          <Button title="Pausar" variant="ghost" size="sm" full={false} onPress={() => router.push('/subscription/pause')} />
        ) : null}
        {caps.canCancel.allowed ? (
          <Button title="Cancelar" variant="ghost" size="sm" full={false} onPress={() => router.push('/subscription/cancel')} />
        ) : null}
      </View>
    </Card>
  );
}

function Banners({ banners }: { banners: Banner[] }) {
  const router = useRouter();
  function open(b: Banner) {
    if (!b.deepLink) return;
    if (b.deepLink.startsWith('/')) router.push(b.deepLink as never);
    else Linking.openURL(b.deepLink).catch(() => toast.error('Não foi possível abrir o link.'));
  }
  return (
    <Section title="Novidades">
      <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.banners}>
        {banners.map((b) => (
          <Pressable key={b.id} onPress={() => open(b)} style={({ pressed }) => [styles.banner, pressed && { opacity: 0.85 }]}>
            {b.imageUrl ? <Image source={{ uri: b.imageUrl }} style={styles.bannerImage} contentFit="cover" /> : null}
            <View style={styles.bannerText}>
              <Text variant="bodyStrong" numberOfLines={2}>
                {b.title}
              </Text>
              {b.subtitle ? (
                <Text variant="caption" tone="muted" numberOfLines={2}>
                  {b.subtitle}
                </Text>
              ) : null}
            </View>
          </Pressable>
        ))}
      </ScrollView>
    </Section>
  );
}

const styles = StyleSheet.create({
  greeting: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginBottom: space(5) },
  greetingText: { gap: 2 },
  flex1: { flex: 1 },
  right: { alignItems: 'flex-end' },
  mt1: { marginTop: space(1) },
  mt2: { marginTop: space(2) },
  mt3: { marginTop: space(3) },
  ctaRow: { flexDirection: 'row', gap: space(2), marginTop: space(4) },
  item: { paddingVertical: space(2), borderBottomWidth: StyleSheet.hairlineWidth, borderBottomColor: colors.border },
  statsRow: { flexDirection: 'row', gap: space(3) },
  stat: { flex: 1, gap: space(1) },
  notice: { marginTop: space(3), padding: space(2.5), borderRadius: radius.md, backgroundColor: colors.accentSoft },
  quick: { flexDirection: 'row', gap: space(2), marginTop: space(2), marginLeft: -space(3) },
  banners: { gap: space(3), paddingRight: space(4) },
  banner: { width: 260, backgroundColor: colors.surface, borderRadius: radius.lg, borderWidth: 1, borderColor: colors.border, overflow: 'hidden' },
  bannerImage: { width: '100%', height: 120 },
  bannerText: { padding: space(3), gap: 2 },
});
