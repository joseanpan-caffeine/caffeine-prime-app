import { useRef, useState } from 'react';
import { Alert, Linking, ScrollView, StyleSheet, View } from 'react-native';
import { useRouter } from 'expo-router';
import { useQueryClient } from '@tanstack/react-query';
import * as WebBrowser from 'expo-web-browser';
import { Ionicons } from '@expo/vector-icons';
import type { Banner, Capabilities, Catalog, Dashboard, Subscription } from '@/api/contracts';
import { errorMessage } from '@/api/client';
import { useAppConfig, useCatalog, useDashboard, useUndoSchedule } from '@/api/hooks';
import {
  AlertCard,
  AppHeader,
  BannerPlaceholder,
  Button,
  CaffeineXIcon,
  CardBrandLogo,
  Carousel,
  DuoCards,
  EmptyState,
  NextBoxCard,
  PlanDetails,
  ProductCard,
  ProductImage,
  Screen,
  SectionHeader,
  SectionList,
  SectionRow,
  Skeleton,
  SkeletonCard,
  Text,
  toast,
  type NextBoxGift,
  type NextBoxItem,
} from '@/components';
import { QuickActions, SavingsStrip, WelcomeCard } from '@/components/WelcomeCard';
import { formatDate, formatMoney } from '@/lib/format';
import { capabilityReasonLabel, fulfillmentLabel } from '@/lib/labels';
import { commitmentMonths, commitmentProgress, editUntilIso, formatDayMonth, formatShortDate, planBadgeLabel, statusBadge, upcomingBillingDates } from '@/lib/prime';
import { signOut } from '@/lib/session';
import { useAuthStore } from '@/store/auth';
import { colors, radius, space } from '@/theme';

const CARD_WIDTH = 300;


export default function Home() {
  const router = useRouter();
  const qc = useQueryClient();
  const user = useAuthStore((s) => s.user);
  const { data, isLoading, isError, error, refetch, isRefetching } = useDashboard();
  const catalog = useCatalog();
  const config = useAppConfig();
  const undo = useUndoSchedule();
  const scrollRef = useRef<ScrollView>(null);
  // Posições Y das seções (preenchidas em onLayout; objeto estável, sem re-render).
  const [anchors] = useState<Record<string, number>>(() => ({}));
  const [planOpen, setPlanOpen] = useState(false);

  const firstName = data?.user.firstName || user?.firstName || '';

  function scrollTo(key: string) {
    const y = anchors[key];
    if (y !== undefined) scrollRef.current?.scrollTo({ y: Math.max(0, y - space(3)), animated: true });
  }

  const header = <AppHeader onMenu={() => router.push('/(tabs)/profile')} onProfile={() => router.push('/(tabs)/profile')} />;

  if (isLoading) {
    return (
      <Screen header={header}>
        <SkeletonCard lines={3} />
        <Skeleton height={150} style={styles.skeletonBlock} />
        <SkeletonCard lines={4} />
      </Screen>
    );
  }

  if (isError || !data) {
    return (
      <Screen header={header} onRefresh={refetch} refreshing={isRefetching}>
        <EmptyState icon="⚠️" title="Não deu para carregar" description={errorMessage(error)} actionLabel="Tentar de novo" onAction={() => refetch()} />
      </Screen>
    );
  }

  const sub = data.subscription;
  const caps = data.capabilities;
  const status = statusBadge(sub?.status, caps);

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

  async function openSupport() {
    const url = config.data?.links.support;
    if (!url) {
      toast.info('Canal de suporte indisponível no momento.');
      return;
    }
    try {
      await WebBrowser.openBrowserAsync(url);
    } catch {
      toast.error('Não foi possível abrir o link.');
    }
  }

  const quickActions = [
    { key: 'box', label: 'Editar\nCaixa', icon: 'options-outline' as const, onPress: () => router.push('/(tabs)/box') },
    { key: 'profile', label: 'Perfil e\nPedidos', icon: 'person-outline' as const, onPress: () => router.push('/(tabs)/profile') },
    { key: 'sub', label: 'Minha\nAssinatura', icon: 'cube-outline' as const, onPress: () => scrollTo('subscription') },
    { key: 'x', label: 'Caffeine\nArmy X', render: <CaffeineXIcon size={20} color={colors.textSecondary} />, onPress: () => scrollTo('benefits') },
    { key: 'club', label: 'Clube de\nVantagens', icon: 'bag-handle-outline' as const, onPress: () => scrollTo('club') },
  ];

  const anchor = (key: string) => (e: { nativeEvent: { layout: { y: number } } }) => {
    anchors[key] = e.nativeEvent.layout.y;
  };

  return (
    <Screen header={header} onRefresh={refetch} refreshing={isRefetching} scrollRef={scrollRef}>
      <WelcomeCard planLabel={planBadgeLabel(sub?.frequency)} firstName={firstName} statusLabel={status.label} statusTone={status.tone} onLogout={() => signOut(qc)}>
        <QuickActions actions={quickActions} />
        <SavingsStrip
          total={formatMoney(data.savings.sinceStart)}
          periodLabel="Últimos 12 meses"
          periods={[{ label: 'Economia', value: formatMoney(data.savings.last12Months) }]}
        />
      </WelcomeCard>

      {sub ? <Alerts sub={sub} data={data} onUndo={onUndo} undoing={undo.isPending} /> : null}

      <Banners banners={data.banners} />

      {sub ? <NextBoxes sub={sub} caps={caps} catalog={catalog.data} /> : null}

      <DuoCards points={data.wallet.points} onPoints={() => scrollTo('benefits')} onClub={() => scrollTo('club')} />

      {sub && catalog.data ? <ExclusiveItems sub={sub} catalog={catalog.data} canEdit={caps.canEdit.allowed} /> : null}

      <SectionList title="Entrega e pagamento">
        <SectionRow
          icon="car-outline"
          title="Endereço de entrega"
          subtitle={
            sub?.shippingAddress
              ? `${sub.shippingAddress.street}, ${sub.shippingAddress.number}${sub.shippingAddress.complement ? `, ${sub.shippingAddress.complement}` : ''}, ${sub.shippingAddress.city}, ${sub.shippingAddress.postalCode}`
              : 'Cadastre seu endereço'
          }
          onPress={() => router.push('/shipping/address')}
        />
        <SectionRow
          icon="cash-outline"
          iconNode={sub?.paymentProfile ? <CardBrandLogo brand={sub.paymentProfile.brand} width={26} height={16} /> : undefined}
          title="Pagamento"
          subtitle={sub?.paymentProfile ? `${sub.paymentProfile.brand} (final ${sub.paymentProfile.lastFour})` : 'Cadastre um cartão'}
          onPress={() => router.push('/payments/cards')}
          last
        />
      </SectionList>

      <View onLayout={anchor('benefits')}>
        <Benefits data={data} catalog={catalog.data} />
      </View>
      <View onLayout={anchor('club')}>
        <ClubSection />
      </View>

      {sub ? (
        <View onLayout={anchor('subscription')}>
          <SectionList title="Minha assinatura">
            <SectionRow
              icon="options-outline"
              title="Editar próxima caixa"
              subtitle={caps.canEdit.allowed ? `Edite até o dia ${formatShortDate(editUntilIso(sub, caps), true)}` : capabilityReasonLabel(caps.canEdit.reason, caps.canEdit.until)}
              onPress={() => router.push('/(tabs)/box')}
            />
            <SectionRow
              icon="grid-outline"
              title="Meu plano"
              onPress={() => setPlanOpen((v) => !v)}
              expanded={
                planOpen ? (
                  <PlanDetails
                    planLabel={sub.frequency}
                    sinceLabel={formatShortDate(sub.startedAt, true)}
                    progress={commitmentProgress(sub, catalog.data?.plans.find((p) => p.frequency === sub.frequency)?.commitmentMonths || commitmentMonths[sub.frequency])}
                    remainingLabel={
                      sub.remainingCommitmentMonths < 0
                        ? 'Plano sem fidelidade.'
                        : sub.remainingCommitmentMonths === 0
                          ? 'Vigência concluída.'
                          : `Restam ${sub.remainingCommitmentMonths} ${sub.remainingCommitmentMonths === 1 ? 'mês' : 'meses'} para finalizar sua vigência`
                    }
                  />
                ) : undefined
              }
            />
            <SectionRow icon="cube-outline" title="Itens que assino" subtitle="Edite os itens da sua assinatura" onPress={() => router.push('/(tabs)/box')} />
            <SectionRow icon="time-outline" title="Histórico de pedidos" onPress={() => router.push('/(tabs)/orders')} />
            {sub.status === 'paused' ? (
              <SectionRow icon="play-outline" title="Retomar assinatura" subtitle={sub.pause ? `Retoma em ${formatDate(sub.pause.resumeAt)}` : undefined} onPress={() => router.push('/subscription/paused')} last />
            ) : sub.status === 'canceled' ? (
              <SectionRow icon="refresh-outline" title="Reativar assinatura" onPress={() => router.push('/subscription/canceled')} last />
            ) : (
              <SectionRow
                icon="pause-outline"
                title="Pausar assinatura"
                subtitle={
                  caps.canPause.allowed
                    ? `Você tem ${caps.canPause.creditsLeft ?? sub.pauseCreditsLeft} ${(caps.canPause.creditsLeft ?? sub.pauseCreditsLeft) === 1 ? 'pausa disponível' : 'pausas disponíveis'}`
                    : capabilityReasonLabel(caps.canPause.reason, caps.canPause.until)
                }
                disabled={!caps.canPause.allowed}
                onPress={() => router.push('/subscription/pause')}
                last
              />
            )}
          </SectionList>
        </View>
      ) : null}

      <SectionList title="Ajuda e suporte">
        <SectionRow icon="headset-outline" title="Fale com nossos especialistas" onPress={openSupport} />
        <SectionRow icon="bulb-outline" title="Ver tutoriais" onPress={() => toast.info('Tutoriais em breve.')} last />
      </SectionList>

      {sub && sub.status !== 'canceled' ? (
        <SectionList>
          <SectionRow
            icon="close-circle-outline"
            title="Cancelar e perder benefícios"
            danger
            subtitle={
              caps.canCancel.allowed
                ? caps.canCancel.earlyWindow
                  ? 'Você está na janela de cancelamento antecipado'
                  : 'Cancele gratuitamente'
                : (caps.canCancel.remainingCommitmentMonths ?? sub.remainingCommitmentMonths) > 0
                  ? `Você poderá cancelar após ${caps.canCancel.remainingCommitmentMonths ?? sub.remainingCommitmentMonths} pagamentos`
                  : capabilityReasonLabel(caps.canCancel.reason, caps.canCancel.until)
            }
            disabled={!caps.canCancel.allowed}
            onPress={() => router.push('/subscription/cancel')}
            last
          />
        </SectionList>
      ) : null}
    </Screen>
  );
}

// ---------- Alertas ----------

function Alerts({ sub, data, onUndo, undoing }: { sub: Subscription; data: Dashboard; onUndo: () => void; undoing: boolean }) {
  const router = useRouter();
  const caps = data.capabilities;
  const [dismissed, setDismissed] = useState<Record<string, boolean>>({});
  const dismiss = (k: string) => () => setDismissed((d) => ({ ...d, [k]: true }));

  return (
    <>
      {caps.hasPendingBill && caps.pendingBill ? (
        <AlertCard
          variant="payment_pending"
          title="Pagamento pendente"
          primaryLabel="Regularizar assinatura"
          onPrimary={() => router.push({ pathname: '/payments/pay/[billId]', params: { billId: caps.pendingBill!.id } })}
        >
          <Text variant="body" tone="secondary">
            Sua fatura de <Text variant="bodyStrong">{formatMoney(caps.pendingBill.amount)}</Text> vence em{' '}
            <Text variant="bodyStrong">{formatShortDate(caps.pendingBill.dueAt, true)}</Text>. Regularize para liberar a edição da caixa e garantir o envio.
          </Text>
        </AlertCard>
      ) : null}

      {sub.status === 'paused' && sub.pause && !dismissed.paused ? (
        <AlertCard
          variant="paused"
          title="Assinatura pausada"
          onDismiss={dismiss('paused')}
          primaryLabel={caps.canResume.allowed ? 'Retomar assinatura' : undefined}
          onPrimary={caps.canResume.allowed ? () => router.push('/subscription/paused') : undefined}
        >
          <Text variant="body" tone="secondary">
            Sua assinatura está pausada por {sub.pause.remainingCycles} de {sub.pause.cycles} {sub.pause.cycles === 1 ? 'ciclo' : 'ciclos'}.
          </Text>
          <Text variant="body" tone="secondary">
            O próximo pagamento será efetivado automaticamente em {formatShortDate(sub.pause.resumeAt, true)}.
          </Text>
        </AlertCard>
      ) : null}

      {sub.status === 'fraud_review' ? (
        <AlertCard variant="under_review" title="Assinatura em análise">
          <Text variant="body" tone="secondary">
            Obrigado por assinar o Caffeine Army Prime! Ainda estamos processando seus dados, mas não se preocupe: em breve você receberá um e-mail com uma atualização sobre sua assinatura.
          </Text>
        </AlertCard>
      ) : null}

      {sub.status === 'canceled' ? (
        <AlertCard
          variant="canceled"
          title="Sentimos sua falta!"
          primaryLabel={caps.canReactivate.allowed ? 'Retomar assinatura' : undefined}
          onPrimary={caps.canReactivate.allowed ? () => router.push('/subscription/canceled') : undefined}
        >
          <Text variant="body" tone="secondary">
            {data.user.firstName}, assine novamente o Caffeine Army Prime e garanta seus benefícios novamente: desconto nos produtos, praticidade em receber em casa e frete grátis.
          </Text>
        </AlertCard>
      ) : null}

      {data.tracking && !dismissed.tracking ? (
        <TrackingAlert data={data} onDismiss={dismiss('tracking')} />
      ) : null}

      {sub.scheduledChange && !dismissed.scheduled ? (
        <AlertCard
          variant="scheduled"
          title="Alteração de caixa agendada!"
          onDismiss={dismiss('scheduled')}
          items={sub.scheduledChange.items.map((i) => ({ quantity: i.quantity, label: [i.title, i.flavor].filter(Boolean).join(' - ') }))}
          question="Deseja editar sua próxima caixa?"
          primaryLabel="Editar caixa"
          onPrimary={() => router.push('/(tabs)/box')}
          secondaryLabel="Desfazer agendamento"
          onSecondary={onUndo}
        >
          <Text variant="body" tone="secondary">
            Após <Text variant="bodyStrong">{formatShortDate(sub.scheduledChange.appliesAt)}</Text>, seu pedido será ajustado de acordo com a configuração selecionada
            {sub.scheduledChange.nextCycleOnly ? ' (apenas no próximo ciclo)' : ''}.{undoing ? ' Desfazendo…' : ''}
          </Text>
        </AlertCard>
      ) : null}
    </>
  );
}

function TrackingAlert({ data, onDismiss }: { data: Dashboard; onDismiss: () => void }) {
  const router = useRouter();
  const t = data.tracking!;
  const [showAll, setShowAll] = useState(false);
  const items = (data.latestBill?.items ?? []).map((i) => ({ quantity: i.quantity, label: [i.title, i.flavor].filter(Boolean).join(' - ') }));
  const visible = showAll ? items : items.slice(0, 3);
  const eta = t.estimatedDeliveryAt ? formatShortDate(t.estimatedDeliveryAt, true) : null;

  const variant = t.status === 'delivered' ? 'delivered' : t.status === 'processing' || t.status === 'pending' ? 'preparing' : t.status === 'failed' ? 'info' : 'in_transit';
  const title = t.status === 'delivered' ? 'Caixa entregue!' : variant === 'preparing' ? 'Caixa em preparo' : t.status === 'failed' ? 'Falha na entrega' : 'Caixa em trânsito!';
  const body =
    t.status === 'delivered'
      ? 'Sua caixa foi entregue. Bom proveito!'
      : variant === 'preparing'
        ? `Sua caixa já entrou em processo de separação${eta ? ` e está prevista para chegar em ` : '.'}`
        : t.status === 'failed'
          ? (t.events[0]?.description ?? fulfillmentLabel[t.status])
          : `Sua caixa já entrou em processo de envio${eta ? ' e está prevista para chegar em ' : '.'}`;

  return (
    <AlertCard
      variant={variant}
      title={title}
      onDismiss={onDismiss}
      items={visible}
      linkLabel={t.trackingUrl ? 'Rastrear pedido' : data.latestBill ? 'Ver pedido' : undefined}
      onLink={
        t.trackingUrl
          ? () => Linking.openURL(t.trackingUrl!).catch(() => toast.error('Não foi possível abrir o rastreio.'))
          : data.latestBill
            ? () => router.push({ pathname: '/orders/[billId]', params: { billId: data.latestBill!.id } })
            : undefined
      }
    >
      <Text variant="body" tone="secondary">
        {body}
        {eta && t.status !== 'delivered' && t.status !== 'failed' ? <Text variant="bodyStrong">{eta}</Text> : null}
        {eta && t.status !== 'delivered' && t.status !== 'failed' ? '.' : ''}
      </Text>
      {items.length > 3 ? (
        <Text variant="small" style={styles.seeMore} onPress={() => setShowAll((v) => !v)}>
          {showAll ? 'Ver menos' : 'Ver tudo'}
        </Text>
      ) : null}
    </AlertCard>
  );
}

// ---------- Banners ----------

function Banners({ banners }: { banners: Banner[] }) {
  const router = useRouter();
  const [index, setIndex] = useState(0);
  const banner = banners[index];
  function open(b: Banner) {
    if (!b.deepLink) return;
    if (b.deepLink.startsWith('/')) router.push(b.deepLink as never);
    else Linking.openURL(b.deepLink).catch(() => toast.error('Não foi possível abrir o link.'));
  }
  if (!banner) return <BannerPlaceholder />;
  return (
    <BannerPlaceholder
      imageUrl={banner.imageUrl}
      title={banner.title}
      subtitle={banner.subtitle}
      onPress={() => (banners.length > 1 && !banner.deepLink ? setIndex((i) => (i + 1) % banners.length) : open(banner))}
      dots={Math.max(2, banners.length)}
      activeDot={index}
    />
  );
}

// ---------- Próximas caixas ----------

function NextBoxes({ sub, caps, catalog }: { sub: Subscription; caps: Capabilities; catalog?: Catalog }) {
  const router = useRouter();
  const products = sub.items.filter((i) => !i.isGift);
  const gifts = sub.items.filter((i) => i.isGift);
  const items: NextBoxItem[] = products.map((i) => ({ id: i.id, handle: i.handle, title: i.title, subtitle: i.flavor, imageUrl: i.imageUrl, quantity: i.quantity }));
  const giftList: NextBoxGift[] = gifts.map((g) => ({ id: g.id, handle: g.handle, title: g.title, imageUrl: g.imageUrl ?? catalog?.gifts.find((c) => c.handle === g.handle)?.imageUrl }));
  const dates = upcomingBillingDates(sub, 2);
  const editUntil = editUntilIso(sub, caps);
  const pending = caps.hasPendingBill;

  return (
    <Carousel title="Minhas próximas caixas" subtitle="Acompanhe seus pedidos mês a mês" icon="cube-outline" itemWidth={CARD_WIDTH} inset={space(4)}>
      {dates.map((date, idx) => (
        <NextBoxCard
          key={date}
          paymentDateLabel={formatDayMonth(date)}
          totalLabel={formatMoney(idx === 0 && sub.scheduledChange ? sub.scheduledChange.total : sub.total)}
          items={idx === 0 && sub.scheduledChange ? sub.scheduledChange.items.filter((i) => !i.isGift).map((i) => ({ id: i.id, title: i.title, subtitle: i.flavor, imageUrl: i.imageUrl, quantity: i.quantity })) : items}
          gifts={giftList}
          editUntilLabel={idx === 0 ? formatShortDate(editUntil) : undefined}
          canEdit={caps.canEdit.allowed}
          pendingPayment={idx === 0 && pending}
          readOnly={idx > 0}
          onEdit={idx === 0 ? () => router.push('/(tabs)/box') : undefined}
          onAddItems={idx === 0 && caps.canEdit.allowed ? () => router.push('/(tabs)/box') : undefined}
          onEditItem={idx === 0 && caps.canEdit.allowed ? () => router.push('/(tabs)/box') : undefined}
        />
      ))}
    </Carousel>
  );
}

// ---------- Itens exclusivos ----------

function ExclusiveItems({ sub, catalog, canEdit }: { sub: Subscription; catalog: Catalog; canEdit: boolean }) {
  const router = useRouter();
  const config = useAppConfig();
  const inBox = new Set(sub.items.map((i) => i.handle));
  const products = catalog.products.filter((p) => !inBox.has(p.handle) && !p.flavors?.some((f) => inBox.has(f.handle)));
  if (products.length === 0) return null;
  const pct = sub.discount.percentage || catalog.plans.find((p) => p.frequency === sub.frequency)?.discountPercentage || 0;
  const highlights = products
    .slice(0, 2)
    .map((p) => p.title)
    .join(' + ');

  async function buy() {
    const url = config.data?.links.subscribeUrl;
    if (!url) {
      toast.info('Compra avulsa disponível no site da Caffeine Army.');
      return;
    }
    try {
      await WebBrowser.openBrowserAsync(url);
    } catch {
      toast.error('Não foi possível abrir a loja.');
    }
  }

  return (
    <Carousel title="Complete sua rotina com itens exclusivos" subtitle={`Garanta os lançamentos do Prime: ${highlights}`} icon="flash-outline" itemWidth={150} inset={space(4)} arrows={false}>
      {products.map((p) => {
        const final = p.price.amount * (1 - pct / 100);
        return (
          <ProductCard
            key={p.handle}
            title={p.title}
            flavor={p.flavors?.[0]?.title ?? p.category}
            spec={p.flavors && p.flavors.length > 1 ? `${p.flavors.length} sabores` : undefined}
            imageUrl={p.imageUrl}
            handle={p.handle}
            fullPriceLabel={pct > 0 ? formatMoney(p.price) : undefined}
            priceLabel={formatMoney(pct > 0 ? final : p.price)}
            discountPercentage={pct > 0 ? pct : undefined}
            outOfStock={!p.inStock}
            onAdd={() => {
              if (!canEdit) {
                toast.info('A edição da caixa está indisponível no momento.');
                return;
              }
              router.push({ pathname: '/(tabs)/box', params: { add: p.handle } });
            }}
            onBuy={buy}
          />
        );
      })}
    </Carousel>
  );
}

// ---------- Benefícios ----------

function Benefits({ data, catalog }: { data: Dashboard; catalog?: Catalog }) {
  const gifts = catalog?.gifts ?? [];
  return (
    <View style={styles.benefits}>
      <Text variant="bodyStrong" tone="secondary" style={styles.benefitsTitle}>
        Benefícios exclusivos
      </Text>
      <SectionHeader iconNode={<CaffeineXIcon size={20} />} title="Programa de pontos: Caffeine Army X" />
      <Text variant="small" tone="secondary" style={styles.benefitsSub}>
        Você possui <Text variant="smallStrong">{data.wallet.points.toLocaleString('pt-BR')} pontos</Text>.{gifts.length > 0 ? ' Confira os itens que você já pode resgatar:' : ''}
      </Text>
      {gifts.length > 0 ? (
        <Carousel itemWidth={150} inset={space(4)} arrows={false}>
          {gifts.map((g, i) => {
            const cost = 300 + ((i * 199) % 700); // custo em pontos: a API ainda não expõe
            return (
              <View key={g.handle} style={styles.giftCard}>
                <ProductImage uri={g.imageUrl} handle={g.handle} title={g.title} width={126} height={110} bg={colors.subtle} />
                <Text variant="bodyStrong" numberOfLines={1}>
                  {g.title}
                </Text>
                <Text variant="caption" tone="purple">
                  <Text variant="captionStrong" tone="purple">
                    {cost} pts
                  </Text>{' '}
                  para resgate
                </Text>
                <Button title="Resgatar" variant="purple" size="sm" onPress={() => toast.info('Resgate de brindes disponível em breve no app.')} disabled={data.wallet.points < cost} />
              </View>
            );
          })}
        </Carousel>
      ) : null}
    </View>
  );
}

const PARTNERS: { name: string; offer: string }[] = [
  { name: 'Naked Nuts', offer: '8% OFF' },
  { name: 'Tia Sônia', offer: '20% OFF' },
  { name: 'Pacco', offer: '10% OFF' },
  { name: 'Hope Resort', offer: '8% OFF' },
  { name: 'Nude', offer: '15% OFF' },
];

function ClubSection() {
  return (
    <View style={styles.club}>
      <SectionHeader
        icon="bag-handle-outline"
        title="Clube de Vantagens"
        subtitle="Até 20% de desconto em parceiros"
        right={<Ionicons name="chevron-forward" size={18} color={colors.text} />}
      />
      <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.partners} style={styles.partnersScroll}>
        {PARTNERS.map((p) => (
          <View key={p.name} style={styles.partner}>
            <View style={styles.partnerLogo}>
              <Text variant="captionStrong" center numberOfLines={2}>
                {p.name}
              </Text>
            </View>
            <Text variant="caption" center numberOfLines={1}>
              {p.name}
            </Text>
            <Text variant="captionStrong" center>
              {p.offer}
            </Text>
          </View>
        ))}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  skeletonBlock: { marginBottom: space(3), borderRadius: radius.md },
  seeMore: { textDecorationLine: 'underline', alignSelf: 'flex-end' },
  benefits: { marginBottom: space(1) },
  benefitsTitle: { marginBottom: space(2) },
  benefitsSub: { marginTop: -space(1), marginBottom: space(3) },
  giftCard: { backgroundColor: colors.surface, borderRadius: radius.md, padding: space(3), gap: space(1) },
  club: { backgroundColor: colors.surface, borderRadius: radius.md, padding: space(4), marginBottom: space(3) },
  partnersScroll: { marginHorizontal: -space(4) },
  partners: { gap: space(3), paddingHorizontal: space(4) },
  partner: { width: 72, alignItems: 'center', gap: 2 },
  partnerLogo: { width: 64, height: 64, borderRadius: radius.pill, backgroundColor: colors.subtle, borderWidth: 1, borderColor: colors.border, alignItems: 'center', justifyContent: 'center', padding: 4, marginBottom: space(1) },
});
