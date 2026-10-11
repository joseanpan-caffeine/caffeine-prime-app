import { useEffect, useMemo, useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { Image } from 'expo-image';
import * as Clipboard from 'expo-clipboard';
import type { Bill, PixCharge } from '@/api/contracts';
import { errorMessage } from '@/api/client';
import { useBill, useDashboard, usePayWithCurrentCard, usePayWithNewCard, usePayWithPix } from '@/api/hooks';
import { Badge, Button, Card, EmptyState, Money, Row, Screen, SkeletonCard, Text, toast } from '@/components';
import { CardForm } from '@/features/payments/CardForm';
import { formatCountdown, formatDate } from '@/lib/format';
import type { TokenizedCard } from '@/lib/vindi';
import { colors, radius, space } from '@/theme';

type Method = 'pix' | 'card' | 'new-card';

export default function PayBill() {
  const { billId, method: initialMethod } = useLocalSearchParams<{ billId: string; method?: string }>();
  const router = useRouter();
  const { data: bill, isLoading, isError, error, refetch } = useBill(billId);
  const { data: dashboard } = useDashboard();
  const [method, setMethod] = useState<Method>(initialMethod === 'card' ? 'card' : 'pix');

  const currentCard = dashboard?.subscription?.paymentProfile ?? bill?.paymentProfile;
  const pixAvailable = dashboard?.capabilities.pendingBill?.id === bill?.id ? dashboard?.capabilities.pendingBill?.pixAvailable !== false : true;

  if (isLoading) {
    return (
      <Screen>
        <SkeletonCard lines={2} />
        <SkeletonCard lines={4} />
      </Screen>
    );
  }
  if (isError || !bill) {
    return (
      <Screen>
        <EmptyState icon="⚠️" title="Fatura não encontrada" description={errorMessage(error)} actionLabel="Tentar de novo" onAction={() => refetch()} />
      </Screen>
    );
  }
  if (bill.status === 'paid') {
    return (
      <Screen>
        <EmptyState icon="✅" title="Fatura paga" description={`Pagamento confirmado${bill.paidAt ? ` em ${formatDate(bill.paidAt)}` : ''}. Obrigado!`} actionLabel="Voltar ao início" onAction={() => router.replace('/(tabs)')} />
      </Screen>
    );
  }

  const tabs: { key: Method; label: string; enabled: boolean }[] = [
    { key: 'pix', label: 'PIX', enabled: pixAvailable },
    { key: 'card', label: 'Cartão atual', enabled: !!currentCard },
    { key: 'new-card', label: 'Novo cartão', enabled: true },
  ];

  return (
    <Screen keyboard>
      <Card tone="accent" title={`Fatura · ciclo ${bill.cycle}`} subtitle={`Vencimento ${formatDate(bill.dueAt)}`} right={<Badge label="Pendente" tone="warning" />}>
        <Money value={bill.amount} variant="display" />
      </Card>

      <View style={styles.tabs}>
        {tabs.map((t) => (
          <Pressable key={t.key} onPress={() => t.enabled && setMethod(t.key)} disabled={!t.enabled} accessibilityRole="tab" accessibilityState={{ selected: method === t.key, disabled: !t.enabled }} style={[styles.tab, method === t.key && styles.tabOn, !t.enabled && styles.tabOff]}>
            <Text variant="small" tone={method === t.key ? 'onAccent' : 'default'} style={styles.tabText}>
              {t.label}
            </Text>
          </Pressable>
        ))}
      </View>

      {method === 'pix' ? <PixPanel bill={bill} /> : null}
      {method === 'card' ? <CurrentCardPanel bill={bill} /> : null}
      {method === 'new-card' ? <NewCardPanel bill={bill} /> : null}
    </Screen>
  );
}

function PixPanel({ bill }: { bill: Bill }) {
  const router = useRouter();
  const payPix = usePayWithPix();
  const pix: PixCharge | undefined = payPix.data?.pix ?? bill.pix;

  useEffect(() => {
    if (!bill.pix && !payPix.data && !payPix.isPending && !payPix.isError) {
      payPix.mutate(bill.id, { onError: (e) => toast.error(errorMessage(e, 'Não foi possível gerar o PIX.')) });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [bill.id]);

  if (!pix) {
    return (
      <Card>
        {payPix.isError ? (
          <>
            <Text variant="small" tone="danger">
              {errorMessage(payPix.error, 'Não foi possível gerar o PIX.')}
            </Text>
            <Button title="Tentar de novo" variant="secondary" size="sm" style={styles.mt3} onPress={() => payPix.mutate(bill.id)} />
          </>
        ) : (
          <SkeletonCard lines={4} />
        )}
      </Card>
    );
  }
  return <PixDetails pix={pix} onRegenerate={() => payPix.mutate(bill.id)} regenerating={payPix.isPending} onPaid={() => router.replace('/(tabs)')} />;
}

function PixDetails({ pix, onRegenerate, regenerating, onPaid }: { pix: PixCharge; onRegenerate: () => void; regenerating: boolean; onPaid: () => void }) {
  const expiresAt = useMemo(() => new Date(pix.expiresAt).getTime(), [pix.expiresAt]);
  const [now, setNow] = useState(() => Date.now());
  useEffect(() => {
    const t = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(t);
  }, []);
  const remaining = expiresAt - now;
  const expired = Number.isFinite(expiresAt) && remaining <= 0;

  async function copy() {
    await Clipboard.setStringAsync(pix.qrCodeText);
    toast.success('Código PIX copiado. Cole no app do seu banco.');
  }

  return (
    <Card>
      <View style={styles.qrWrap}>
        <Image source={{ uri: pix.qrCodeImageUrl }} style={styles.qr} contentFit="contain" />
      </View>
      <Row style={styles.mt3}>
        <Text variant="small" tone="muted">
          {expired ? 'QR Code expirado' : 'Expira em'}
        </Text>
        <Text variant="mono" tone={expired ? 'danger' : remaining < 5 * 60_000 ? 'accent' : 'default'}>
          {expired ? '—' : formatCountdown(remaining)}
        </Text>
      </Row>
      {expired ? (
        <Button title="Gerar novo PIX" variant="secondary" style={styles.mt3} onPress={onRegenerate} loading={regenerating} />
      ) : (
        <>
          <Text variant="caption" tone="dim" style={styles.mt3}>
            PIX copia e cola
          </Text>
          <Text variant="mono" tone="muted" numberOfLines={3} selectable>
            {pix.qrCodeText}
          </Text>
          <Button title="Copiar código PIX" style={styles.mt3} onPress={copy} />
        </>
      )}
      <Text variant="caption" tone="dim" center style={styles.mt3}>
        A confirmação é automática em até alguns minutos. Se o PIX vencer, a cobrança vai para o cartão à meia-noite.
      </Text>
      <Button title="Já paguei" variant="ghost" size="sm" onPress={onPaid} />
    </Card>
  );
}

function CurrentCardPanel({ bill }: { bill: Bill }) {
  const router = useRouter();
  const { data: dashboard } = useDashboard();
  const pay = usePayWithCurrentCard();
  const card = dashboard?.subscription?.paymentProfile ?? bill.paymentProfile;

  function onPay() {
    pay.mutate(bill.id, {
      onSuccess: (b) => {
        if (b.status === 'paid') {
          toast.success('Pagamento aprovado!');
          router.replace('/(tabs)');
        } else {
          toast.info('Pagamento enviado. Aguardando confirmação da operadora.');
        }
      },
      onError: (e) => toast.error(errorMessage(e, 'Pagamento recusado. Tente outro cartão.')),
    });
  }

  return (
    <Card title="Cobrar no cartão atual">
      {card ? (
        <Row>
          <View>
            <Text variant="bodyStrong">
              {card.brand} •••• {card.lastFour}
            </Text>
            <Text variant="caption" tone="muted">
              {card.holderName} · {card.expiration}
            </Text>
          </View>
          {card.isDefault ? <Badge label="Padrão" tone="accent" /> : null}
        </Row>
      ) : (
        <Text variant="small" tone="muted">
          Nenhum cartão cadastrado.
        </Text>
      )}
      <Button title={`Pagar ${bill.amount.amount.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' })}`} style={styles.mt3} onPress={onPay} loading={pay.isPending} disabled={!card} />
    </Card>
  );
}

function NewCardPanel({ bill }: { bill: Bill }) {
  const router = useRouter();
  const pay = usePayWithNewCard();

  async function onTokenized(card: TokenizedCard) {
    await pay
      .mutateAsync(
        { billId: bill.id, body: { gatewayToken: card.gatewayToken, paymentCompanyCode: card.paymentCompanyCode } },
        {
          onSuccess: (b) => {
            toast.success(b.status === 'paid' ? 'Pagamento aprovado!' : 'Pagamento enviado.');
            router.replace('/(tabs)');
          },
          onError: (e) => toast.error(errorMessage(e, 'Pagamento recusado.')),
        },
      )
      .catch(() => undefined);
  }

  return (
    <Card title="Pagar com outro cartão" subtitle="O novo cartão passa a ser o padrão da assinatura.">
      <CardForm submitLabel="Pagar com este cartão" onTokenized={onTokenized} busy={pay.isPending} />
    </Card>
  );
}

const styles = StyleSheet.create({
  mt3: { marginTop: space(3) },
  tabs: { flexDirection: 'row', backgroundColor: colors.surface, borderRadius: radius.md, padding: 4, marginBottom: space(4), borderWidth: 1, borderColor: colors.border },
  tab: { flex: 1, paddingVertical: space(2.5), borderRadius: radius.sm, alignItems: 'center' },
  tabOn: { backgroundColor: colors.accent },
  tabOff: { opacity: 0.4 },
  tabText: { fontWeight: '600' },
  qrWrap: { alignSelf: 'center', padding: space(3), backgroundColor: '#FFFFFF', borderRadius: radius.md },
  qr: { width: 220, height: 220 },
});
